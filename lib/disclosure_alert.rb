# frozen_string_literal: true

require 'active_record'
require 'tzinfo'
ActiveRecord::Base.establish_connection ENV['DATABASE_URL']

# DisclosureAlert lets you know when there are new Campaign Finance filings.
module DisclosureAlert
  autoload :Downloader, 'downloader'
  autoload :Emailer, 'emailer'
  autoload :Netfile, 'netfile/client'

  autoload :Filing, 'models/filing'
  autoload :AlertSubscriber, 'models/alert_subscriber'
end
