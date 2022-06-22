require "json"
require "twilio-ruby"
require "telephone_number"
require "fileutils"
require "logger"
require "httparty"
require "sftp"

class Processor
  def initialize(
    sftp: SFTP.client,
    input_directory: ENV.fetch("SMS_DIR"),
    output_directory: ENV.fetch("PROCESSED_SMS_DIR"),
    sender: Sender.new,
    logger: Logger.new($stdout),
    file_class: File
  )
    @sftp = sftp
    @input_directory = input_directory
    @output_directory = output_directory
    @sender = sender
    @logger = logger
    @file_class = file_class
  end

  def run
    @logger.info("Started Processing SMS messages")
    starting_files = sms_files
    summary = {total_files: starting_files.count, num_files_sent: 0, num_files_not_sent: 0}
    starting_files.each do |file|
      @logger.info("Processing #{file}")
      base_file = @file_class.basename(file)
      @sftp.get(file, "/app/scratch/#{base_file}")
      message = Message.new(@file_class.read("/app/scratch/#{base_file}"))
      if !message.valid_phone_number?
        @logger.error("Invalid phone number for #{base_file}")
        @sftp.rename(file, "sms/processed/#{base_file}")
        @file_class.delete("/app/scratch/#{base_file}")
        summary[:num_files_not_sent] = summary[:num_files_not_sent] + 1
        next
      end
      response = @sender.send(message)
      @logger.info("status: #{response.status}, to: #{response.to}, body: #{response.body}")
      @sftp.rename(file, "sms/processed/#{base_file}")
      @file_class.delete("/app/scratch/#{base_file}")
      summary[:num_files_sent] = summary[:num_files_sent] + 1
    end
    summary[:total_files_in_input_directory_after_script] = sms_files.count
    @logger.info("Finished Processing SMS Messages\n#{summary}")
    begin
      HTTParty.get(ENV.fetch("PUSHMON_URL"))
    rescue
      @logger.error("Failed to contact Pushmon")
    end
  end

  private

  def sms_files
    @sftp.ls(@input_directory).select { |f| f.match(/Ful/) }
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

class FakeSftp
  def dir
    FakeDir.new
  end

  def download!(file_path)
    File.read(file_path)
  end

  def rename!(input, output)
    FileUtils.mv(input, output)
  end

  class FakeDir
    def glob(*args)
      FileUtils.cd(args[0]) do
        Dir.glob(args[1]).map do |file|
          OpenStruct.new(name: file, file?: !File.directory?(file))
        end
      end
    end
  end
end
