heroku commands:

```bash
heroku create disclosure-alert
heroku git:remote --app disclosure-alert
heroku addons:create heroku-postgresql:hobby-dev
heroku config:set MAILGUN_API_KEY=key-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

deploying:

```bash
git push heroku master
heroku run rake db:migrate
```

running:
```
heroku run rake download_and_email_daily
```
