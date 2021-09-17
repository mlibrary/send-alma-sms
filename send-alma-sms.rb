require_relative './lib/send-alma-sms'
require 'optparse'
require 'net/sftp'
require 'ed25519'
require 'bcrypt_pbkdf'
require 'base64'

params = {}
OptionParser.new do |opts|
  opts.on("--nosend")
  opts.on("--nosftp")
end.parse!(into: params)
inputs = {}
inputs[:sender] = Sender.new(FakeTwilioClient.new) if params[:nosend]
if params[:nosftp]
  inputs[:sftp] = FakeSftp.new
else
  inputs[:sftp] = Net::SFTP.start(ENV.fetch('HOST'), ENV.fetch('USER'),
                key_data: Base64.decode64(ENV.fetch('KEY') ),
                keys: [],
                keys_only: true
               ) 
end
Processor.new(**inputs).run
#Net::SFTP.start(ENV.fetch('HOST'), ENV.fetch('USER'),
                #key_data: Base64.decode64(ENV.fetch('KEY') ),
                #keys: [],
                #keys_only: true
                ##, ENV.fetch('PASSWORD')
               #) do |sftp|
  #if params["nosend"]
    #Processor.new(sftp: sftp, sender: Sender.new(FakeTwilioClient.new)).run
  #else
    #Processor.new(sftp: sftp).run
  #end
#end

