#! /usr/local/bin/ruby
require_relative "./lib/send-alma-sms"
require "optparse"

params = {}
OptionParser.new do |opts|
  opts.on("--nosend")
end.parse!(into: params)
inputs = {}
inputs[:sender] = Sender.new(FakeTwilioClient.new) if params[:nosend]

Processor.new(**inputs).run
