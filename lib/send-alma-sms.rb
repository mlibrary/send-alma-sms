require 'json'
require 'twilio-ruby'
require 'telephone_number'
require 'fileutils'
require 'logger'
require 'byebug'

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
    files = @sftp.dir.glob(@input_directory, "**/*").filter_map{|x| "#{@input_directory}#{x.name}" if x.file?}
    sms_files = files.select{|f| f.match(/Ful/)}
    sms_files.each do | file |
      @logger.info("Processing #{file}")
      message = Message.new(@sftp.download!(file)) 
      if !message.valid_phone_number?
        @logger.error("Invalid phone number")
        next
      end
      response = @sender.send(message)
      @logger.info("status: #{response.status}, to: #{response.to}, body: #{response.body}")
      @sftp.rename(file, "#{@output_directory}/#{File.basename(file)}")
    end
    @logger.info("Finished Processing SMS Messages")
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
      { to: to, body: body, messaging_service_sid: messaging_service_sid} 
    end
  end
end
