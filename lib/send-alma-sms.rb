require "json"
require "twilio-ruby"
require "telephone_number"
require "fileutils"
require "logger"
require "sftp"

class Processor
  def initialize(
    sftp: SFTP.client,
    input_directory: ENV.fetch("SMS_DIR"),
    output_directory: ENV.fetch("PROCESSED_SMS_DIR"),
    sender: Sender.new,
    logger: Logger.new($stdout),
    file_class: File,
    sms_file_class: SMSFile
  )
    @sftp = sftp
    @input_directory = input_directory
    @output_directory = output_directory
    @sender = sender
    @logger = logger
    @file_class = file_class
    @sms_file_class = sms_file_class
  end

  def run
    @logger.info("Started Processing SMS messages")
    summary = {total_files: sms_files.count, num_files_sent: 0, num_files_not_sent: 0, num_files_error: 0}
    sms_files.each do |file|
      @logger.info("Processing #{file}")
      sms_file = @sms_file_class.new(file)
      @sftp.get(sms_file.remote_file, sms_file.scratch_path)
      message = Message.new(@file_class.read(sms_file.scratch_path))

      begin
        response = @sender.send(message)
        @logger.info("status: #{response.status}, to: #{response.to}, body: #{response.body}")
        summary[:num_files_sent] = summary[:num_files_sent] + 1
      rescue Twilio::REST::TwilioError => e
        error_message(sms_file: sms_file, error: e)
        summary[:num_files_not_sent] = summary[:num_files_not_sent] + 1
        summary[:num_files_error] = summary[:num_files_error] + 1
        next # don't rename remotely
      rescue => e
        error_message(sms_file: sms_file, error: e)
        summary[:num_files_error] = summary[:num_files_error] + 1
      end
      @sftp.rename(sms_file.remote_file, sms_file.proccessed_path)
    end
    @logger.info("Finished Processing SMS Messages\n#{summary}")
    summary
  end

  private

  def error_message(sms_file:, error:)
    @logger.error("For file: #{sms_file.base_name}: #{error.message}")
  end

  def sms_files
    @sms_files ||= @sftp.ls(@input_directory).select { |f| f.match(/Ful/) }
  end
end

class SMSFile
  attr_reader :remote_file, :base_name
  def initialize(remote_file)
    @remote_file = remote_file
    @base_name = File.basename(remote_file)
  end

  def scratch_path
    "/app/scratch/#{@base_name}"
  end

  def proccessed_path
    "sms/processed/#{@base_name}"
  end
end

class Sender
  def initialize(client = Twilio::REST::Client.new(ENV.fetch("TWILIO_ACCT_SID"), ENV.fetch("TWILIO_AUTH_TOKEN")))
    @client = client
  end

  def send(msg)
    @client.messages.create(
      to: msg.to,
      body: msg.body,
      messaging_service_sid: ENV.fetch("MESSAGING_SERVICE_SID")
    )
  end
end

class Message
  def initialize(msg)
    @msg = msg.split("\n")
    @phone = TelephoneNumber.parse(@msg.first.strip, :US)
  end

  def to
    @phone.e164_number
  end

  def body
    # get array elements 2 - end; reject empty lines; join with a space.
    @msg[2..].filter { |x| x != "" }.join(" ")
  end

  def valid_phone_number?
    @phone.valid?
  end
end

# put this into Sender to not actually send Twilio messages
class FakeTwilioClient
  def messages
    Messages.new
  end

  class Messages
    def create(to:, body:, messaging_service_sid:)
      OpenStruct.new(to: to, body: body, messaging_service_sid: messaging_service_sid, status: "OK")
    end
  end
end
