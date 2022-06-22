#! /usr/local/bin/ruby
require_relative "./lib/send-alma-sms"
require "optparse"

inputs = {}
OptionParser.new do |opts|
  opts.on("--nosend") do
    inputs[:sender] = Sender.new(FakeTwilioClient.new)
  end
end.parse!

Processor.new(**inputs).run
