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
docker-compose run --rm web bundle exec ruby send-alma-sms.rb --nosend
```

## Further Context
To actually send SMS messages you'll need to:
1. Change the twilio values in `.env` to real twilio values 
2. Change the phone number in `tmp/test_files/Ful_somefile.txt` to a real value 
3. Run the `send-alma-sms.rb` without the `--nosend` flag.

## Tests
To run the test suite:
```
docker-compose run --rm web bundle exec rspec
```

Tests are run in github actions after every push to github.
