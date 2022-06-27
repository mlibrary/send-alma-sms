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
3. Set the `BUNDLE_RUBYGEMS__PKG__GITHUB__COM` env var to your Github Personal Acess token with package:read scope

4. Build the image
```
docker-compose build
```
5. Bundle install the gems
```
docker-compose run --rm web bundle install
```
6. Set up the ssh keys
```
./set_up_development_ssh_keys.sh
```
7. Set up the sftp folders
```
./set_up_sms_dir.sh
```
8. Run the test script that doesn't send any SMS messages
```
docker-compose run --rm web bundle exec ruby send-alma-sms.rb --nosend
```

## Further Context
To actually send SMS messages you'll need to:
1. Change the twilio values in `.env` to real twilio values 
2. Run the `send-alma-sms.rb` without the `--nosend` flag. (But still with the `--nosftp`)

## Tests
To run the test suite:
```
docker-compose run --rm web bundle exec rspec
```

Tests are run in github actions after every push to github.
