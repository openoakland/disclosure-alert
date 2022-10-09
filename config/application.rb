require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DisclosureAlert
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Pacific Time (US & Canada)"
    config.eager_load_paths << Rails.root.join("app", "lib")

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
  end
end
