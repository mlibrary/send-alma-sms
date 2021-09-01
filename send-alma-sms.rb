require_relative './lib/send-alma-sms'
require 'optparse'

#Processor.new.run

params = {}
OptionParser.new do |opts|
  opts.on("--nosend")
end.parse!(into: params)

if params["nosend"]
  Processor.new(sender: Sender.new(FakeTwilioClient.new)).run
else
  Processor.new.run
end

