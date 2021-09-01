`mkdir -p #{ENV.fetch('SMS_DIR')}`
`mkdir -p #{ENV.fetch('PROCESSED_SMS_DIR')}`
`cp spec/sample_message.txt #{ENV.fetch('SMS_DIR')}/Ful_somefile.txt`
`rm #{ENV.fetch('PROCESSED_SMS_DIR')}/*`
