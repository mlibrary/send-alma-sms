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
