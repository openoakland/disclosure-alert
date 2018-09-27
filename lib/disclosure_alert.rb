# frozen_string_literal: true

require 'active_record'
require 'tzinfo'
ActiveRecord::Base.establish_connection 'postgresql://localhost/disclosure-alert'

# DisclosureAlert lets you know when there are new Campaign Finance filings.
module DisclosureAlert
  autoload :Downloader, 'downloader'
  autoload :Emailer, 'emailer'
  autoload :Netfile, 'netfile/client'

  autoload :Filing, 'models/filing'
end
