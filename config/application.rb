require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DisclosureAlert
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    config.autoload_paths << Rails.root.join('app', 'lib')

    # Configure for sending email:
    config.action_mailer.delivery_method = :mailgun
    config.action_mailer.mailgun_settings = {
      api_key: ENV['MAILGUN_API_KEY'],
      domain: 'mailgun.opendisclosure.io',
    }
    config.action_mailer.default_url_options = {
      host: ENV['APP_HOST'],
    }
    config.action_mailer.preview_path = Rails.root.join('spec', 'mailers', 'previews')

    config.assets.precompile << 'email.scss'


    config.time_zone = 'Pacific Time (US & Canada)'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
