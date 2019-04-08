AhoyEmail.api = true
AhoyEmail.secret_token = Rails.application.secret_key_base
AhoyEmail.default_options[:url_options] = {
  host: ENV['APP_HOST'] || 'localhost',
}

