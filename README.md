## local setup:
```bash
# install and start PostgreSQL:
brew install postgresql
brew services start postgresql

# create the postgresql database:
createdb disclosure-alert
createdb disclosure-alert_test

# install ruby
# We recommend doing it with rbenv, there are instructions here:
# https://github.com/rbenv/rbenv#homebrew-on-macos
# After installing rbenv:
rbenv install         # <- this installs ruby

# install ruby dependencies:
gem install bundler
bundle install

# initialize the database
bin/rails db:schema:load

# run the server!!
bin/rails server      # <- check it out at http://localhost:3000

# view the email rendering in-browser:
bin/rails disclosure_alert:download      # <- download the filings
# then: go to this URL:
open http://localhost:3000/rails/mailers/alert_mailer/daily_alert


# if you subscribe using the web interface, you can generate an email to
# yourself. First, you will need to configure Mailgun. Get the value from Tom or
# set up your own mailgun account. Then:
cp .env.development .env.local
# edit .env.local and put the API key value in there
bin/rails disclosure_alert:download_and_email_daily
```

## deploying to Heroku:
```bash
heroku create disclosure-alert
heroku git:remote --app disclosure-alert
heroku addons:create heroku-postgresql:hobby-dev
heroku addons:create scheduler:standard
heroku config:set MAILGUN_API_KEY=key-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
heroku config:set APP_HOST=your-app-name.herokuapp.com
heroku addons:open scheduler
# create a scheduled task for:
bin/rails disclosure_alert:download_and_email_daily
# that runs daily at 11:00UTC (4am PDT)
```

## deploying:
```bash
git push heroku master
heroku run bin/rails db:migrate
```

## running:
```
heroku run bin/rails disclosure_alert:add_daily_subscriber
heroku run bin/rails disclosure_alert:download_and_email_daily
```
