#! /usr/local/bin/ruby
require_relative "./lib/send-alma-sms"
require "optparse"
require "yabeda"
require "yabeda/prometheus"

Yabeda.configure do
  gauge :send_alma_sms_last_success, comment: "Time that Alma sms messages were successfully sent"
  gauge :send_alma_sms_num_messages_sent, comment: "Number of Alma sms messages sent in a job"
  gauge :send_alma_sms_num_messages_not_sent, comment: "Number of Alma sms messages that caused an error"
  gauge :send_alma_sms_num_messages_error, comment: "Number of Alma sms messages that were NOT successfully sent"
end
Yabeda.configure!

start_time = Time.now.to_i

inputs = {}
OptionParser.new do |opts|
  opts.on("--nosend") do
    inputs[:sender] = Sender.new(FakeTwilioClient.new)
  end
end.parse!

results = Processor.new(**inputs).run
Yabeda.send_alma_sms_num_messages_sent.set({}, results[:num_files_sent])
Yabeda.send_alma_sms_num_messages_not_sent.set({}, results[:num_files_not_sent])
Yabeda.send_alma_sms_num_messages_error.set({}, results[:num_files_error])
Yabeda.send_alma_sms_last_success.set({}, start_time)
begin
  Yabeda::Prometheus.push_gateway.add(Yabeda::Prometheus.registry)
rescue
  Logger.new($stdout).error("Failed to contact the push gateway")
end
