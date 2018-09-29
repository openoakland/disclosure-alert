heroku commands:

```bash
heroku create disclosure-alert
heroku git:remote --app disclosure-alert
heroku addons:create heroku-postgresql:hobby-dev
heroku addons:create scheduler:standard
heroku config:set MAILGUN_API_KEY=key-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
heroku addons:open scheduler
# create a scheduled task for:
#   rake download_and_email_daily
# that runs daily at 11:00UTC (4am PDT)
```

deploying:

```bash
git push heroku master
heroku run rake db:migrate
```

running:
```
heroku run rake add_daily_subscriber
heroku run rake download_and_email_daily
```
