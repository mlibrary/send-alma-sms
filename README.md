# send-alma-sms
This is a cronjob that sends SMS messages from Alma

It runs on the Kubernetes Cluster

The configuration for this cronjob is in the [alma-utilies-kube](https://github.com/mlibrary/alma-utilities-kube) repository

## Developer Setup
1. Clone the repository
2. Copy `.env-example` to `.env`
```
cp .env-example .env
```
3. Build the image
```
docker-compose build
```
4. Bundle install the gems
```
docker-compose run --rm web bundle install
```
5. Set up the test folders
```
docker-compose run --rm web bundle exec ruby set-up-test-folder.rb
```
6. Run the test script that doesn't send any SMS messages
```
docker-compose run --rm web bundle exec ruby send-alma-sms.rb --nosend --nosftp
```

## Further Context
To actually send SMS messages you'll need to:
1. Change the twilio values in `.env` to real twilio values 
2. Change the phone number in `tmp/test_files/Ful_somefile.txt` to a real value 
3. Run the `send-alma-sms.rb` without the `--nosend` flag. (But still with the `--nosftp`)

To run the script with data from a remote serve you need to set up the environment variables appropriately.
That is, the `SMS_DIR` and `PROCESSED_SMS_DIR` need to exist on the remote machine, and you need the `HOST`, `USER`, and `KEY`

`KEY` is the base64 encoded private ssh key. Use: `cat your_private_key_file | base64 -w 0`

## Tests
To run the test suite:
```
docker-compose run --rm web bundle exec rspec
```

Tests are run in github actions after every push to github.
