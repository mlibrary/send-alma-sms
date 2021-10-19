require 'json'
require 'twilio-ruby'
require 'telephone_number'
require 'fileutils'
require 'logger'
require 'byebug'
require 'httparty'

class Processor
  def initialize(
                 sftp:,
                 input_directory: ENV.fetch("SMS_DIR"), 
                 output_directory: ENV.fetch("PROCESSED_SMS_DIR"),
                 sender: Sender.new, 
                 logger: Logger.new(STDOUT)
                )
    @sftp = sftp
    @input_directory = input_directory
    @output_directory = output_directory
    @sender = sender
    @logger = logger
  end
  def run
    @logger.info("Started Processing SMS messages")
    starting_files = sms_files
    summary = { total_files: starting_files.count, num_files_sent: 0, num_files_not_sent: 0}
    starting_files.each do | file |
      @logger.info("Processing #{file}")
      message = Message.new(@sftp.download!(file)) 
      if !message.valid_phone_number?
        @logger.error("Invalid phone number for #{File.basename(file)}")
        @sftp.rename!(file, "#{@output_directory}/#{File.basename(file)}")
        summary[:num_files_not_sent] = summary[:num_files_not_sent] + 1
        next
      end
      response = @sender.send(message)
      @logger.info("status: #{response.status}, to: #{response.to}, body: #{response.body}")
      @sftp.rename!(file, "#{@output_directory}/#{File.basename(file)}")
      summary[:num_files_sent] = summary[:num_files_sent] + 1
    end
    summary[:total_files_in_input_directory_after_script] = sms_files.count
    @logger.info("Finished Processing SMS Messages\n#{summary}")
    HTTParty.post(ENV.fetch('SLACK_URL'), body: {text: "Finished processing sms messages\n#{summary}"}.to_json)
  end

  private
  def sms_files
    files = @sftp.dir.glob(@input_directory, "**").filter_map{|x| "#{@input_directory}/#{x.name}" if x.file?}
    files.select{|f| f.match(/Ful/)}
  end
   
end

class Sender
  def initialize(client = Twilio::REST::Client.new(ENV.fetch('TWILIO_ACCT_SID'), ENV.fetch('TWILIO_AUTH_TOKEN'))) 
    @client = client
  end
  def send(msg)
    @client.messages.create(
      to: msg.to,
      body: msg.body,
      messaging_service_sid: ENV.fetch('MESSAGING_SERVICE_SID')
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
    @msg[2..-1].filter{|x| x != "" }.join(' ')
  end
  def valid_phone_number?
    @phone.valid?
  end
end

#put this into Sender to not actually send Twilio messages
class FakeTwilioClient
  def messages
    Messages.new
  end
  class Messages
    def create(to:,body:,messaging_service_sid:)
      OpenStruct.new( to: to, body: body, messaging_service_sid: messaging_service_sid, status: 'OK') 
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
          OpenStruct.new(name: file, file?: !File.directory?(file) )
        end
      end
    end
  end
end
