require 'mailgun-ruby'
require 'haml'

module DisclosureAlert
  class Emailer
    RECIPIENTS = [
      { to: 'tomdooner@gmail.com' },
      { to: 'sdoran@oaklandca.gov', cc: 'ALaraFranco@oaklandca.gov' },
      { to: 'elinaru@gmail.com' },
    ].freeze

    def initialize(date)
      @date = date
    end

    def send_email
      puts '==================================================================='
      puts 'Emailing:'
      puts
      puts "Filings in date range: #{filings_in_date_range.length}"
      puts '==================================================================='
      return if filings_in_date_range.none?

      mailgun = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])

      RECIPIENTS.each do |recipient_hash|
        mailgun.send_message('tdooner.com', recipient_hash.merge(
          from: 'disclosure-alerts@tdooner.com',
          subject: "New Campaign Disclosure filings on #{@date}",
          html: email_html
        ))
      end
    end

    private

    # helper methods for the email view
    class HamlHelpers
      def format_money(amount)
        '$' + amount.round.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
      end
    end

    def email_html
      template = File.read(File.expand_path('../templates/new_filings_email.haml', __dir__))
      engine = Haml::Engine.new(template)
      engine.render(HamlHelpers.new,
        filings: filings_in_date_range
      )
    end

    def filings_in_date_range
      Filing.filed_on_date(@date)
    end
  end
end
