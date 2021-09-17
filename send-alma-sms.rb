require_relative './lib/send-alma-sms'
require 'optparse'
require 'net/sftp'
require 'ed25519'
require 'bcrypt_pbkdf'
require 'base64'

params = {}
OptionParser.new do |opts|
  opts.on("--nosend")
end.parse!(into: params)

Net::SFTP.start(ENV.fetch('HOST'), ENV.fetch('USER'),
                key_data: Base64.decode64(ENV.fetch('KEY') ),
                keys: [],
                keys_only: true
                #, ENV.fetch('PASSWORD')
               ) do |sftp|
  if params["nosend"]
    Processor.new(sftp: sftp, sender: Sender.new(FakeTwilioClient.new)).run
  else
    Processor.new(sftp: sftp).run
  end
end

