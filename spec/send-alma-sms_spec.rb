describe Processor do
  def total_files_in(directory)
    Dir[File.join(directory,'**','*')].count{|file| File.file?(file)}
  end
  before(:each) do
    current_directory = Dir.pwd
    @files_directory = "#{current_directory}/send-alma-sms-tests"
    @processed_directory = "#{current_directory}/send-alma-sms-tests-processed"
    `mkdir #{@files_directory}`
    `mkdir #{@processed_directory}`

    @sample_message_path = "#{current_directory}/spec/sample_message.txt"
    twilio_response = double('TwilioClient', status: 'success', to: 'someone', body: 'body')
    @sender_double = instance_double(Sender, send: twilio_response)
    @logger_double = instance_double(Logger, info: nil, error: nil)
  end
  after(:each) do
    `rm -r #{@files_directory}`
    `rm -r #{@processed_directory}`
  end
  subject do
    described_class.new(input_directory: @files_directory, output_directory: @processed_directory, sender: @sender_double, logger: @logger_double).run
  end
  it "moves file to processed directory" do
    `cp #{@sample_message_path} #{@files_directory}/FulSomeFile.txt`
    subject
    expect(total_files_in(@files_directory)).to eq(0)
    expect(total_files_in(@processed_directory)).to eq(1)
  end
  it "handles folders of files" do
    `mkdir #{@files_directory}/kind_of_message`
    `cp #{@sample_message_path} #{@files_directory}/kind_of_message/FulSomeFile.txt`
    subject
    expect(total_files_in(@files_directory)).to eq(0)
    expect(total_files_in(@processed_directory)).to eq(1)
  end
  it "ignores files that don't start with Full" do
    `cp #{@sample_message_path} #{@files_directory}/wrong_name.txt`
    subject
    expect(total_files_in(@files_directory)).to eq(1)
    expect(total_files_in(@processed_directory)).to eq(0)
  end
  it "sends the messages for each file" do
    `cp #{@sample_message_path} #{@files_directory}/FulSomeFile.txt`
    `mkdir #{@files_directory}/kind_of_message`
    `cp #{@sample_message_path} #{@files_directory}/kind_of_message/FulSomeOtherFile.txt`
    expect(@sender_double).to receive(:send).twice
    subject
    expect(total_files_in(@processed_directory)).to eq(2)
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
    it "uses and Message object and sends message with twilio" do
      expect(@messages_double).to receive(:create)
      expect(@message).to receive(:to)
      expect(@message).to receive(:body)
      subject.send(@message)
    end
    it "exists with invalid phone number"
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
