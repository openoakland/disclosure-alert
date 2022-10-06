if ENV['SENTRY_DSN']
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
  end
end
