describe Processor do
  before(:each) do
    @sftp_dir = double('SFTP::Dir', glob: nil)
    @sftp_file = double('SFTP::File', "download"=> nil)
    @sftp = double('SFTP', file: @sftp_file, dir: @sftp_dir, rename: nil, download!: nil)
    twilio_response = double('TwilioClient', status: 'success', to: 'someone', body: 'body')
    @sender_double = instance_double(Sender, send: twilio_response)
    @logger_double = instance_double(Logger, info: nil, error: nil)
    stub_request(:post, ENV.fetch('SLACK_URL'))
  end
  subject do
    described_class.new(sftp: @sftp, sender: @sender_double, logger: @logger_double).run
  end
  it "skips files that don't start with Ful" do
    allow(@sftp_dir).to receive(:glob).and_return([double('SFTP::Name', name: 'some_wrong_file', file?: true)])
    expect(@logger_double).to receive(:info).with("Finished Processing SMS Messages")
    subject
  end
  it "processes files that do start with Ful" do
    files = ['FulSomeFile', 'FulSomeOtherFile', 'some_wrong_file'].map{|x| double('SFTP::Name', name: x, file?: true) }
    allow(@sftp_dir).to receive(:glob).and_return(files)
    allow(@sftp).to receive("download!").and_return(File.read('./spec/sample_message.txt'))
    expect(@logger_double).to receive(:info).with("Processing #{ENV.fetch("SMS_DIR")}/FulSomeFile")
    expect(@logger_double).to receive(:info).with("Processing #{ENV.fetch("SMS_DIR")}/FulSomeOtherFile")
    expect(@logger_double).not_to receive(:info).with("Processing #{ENV.fetch("SMS_DIR")}/some_wrong_file")
    subject

  end

end
describe Sender do
  before(:each) do
    @messages_double = instance_double(Twilio::REST::Api::V2010::AccountContext::MessageList, create: nil)
    @client_double = instance_double(Twilio::REST::Client, messages: @messages_double)
    @message = instance_double(Message, to: 'number', body: 'body')
  end

  subject do
    described_class.new(@client_double)
  end
  context "#send" do
    it "uses a Message object and sends message with twilio" do
      expect(@messages_double).to receive(:create)
      expect(@message).to receive(:to)
      expect(@message).to receive(:body)
      subject.send(@message)
    end
  end
end
describe Message do
  before(:each) do
    @message = File.read('./spec/sample_message.txt').split("\n")
  end
  subject do
    described_class.new(@message.join("\n"))
  end
  context "#to" do
    it "returns a valid phone number" do
      expect(subject.to).to eq('+17345553333')
    end
    it "handles first line with trailing and leading whitespace" do
      @message[0] = "   #{@message[0]}   "
      expect(subject.to).to eq('+17345553333')
    end
  end
  context "#valid_phone_number?" do
    it "returns true if the phone number is valid" do
      expect(subject.valid_phone_number?).to eq(true)
    end
    it "returns false if the phone number is not valid" do
      @message[0] = "abcdefg"
      expect(subject.valid_phone_number?).to eq(false)
    end
  end
  context "#body" do
    it "returns the body" do
      expect(subject.body).to eq("This is a sample message It has more than one line")
    end
  end
end
