require 'mailgun-ruby'
require 'haml'

module DisclosureAlert
  class Emailer
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

      Mailgun::Client
        .new(ENV['MAILGUN_API_KEY'])
        .send_message('tdooner.com',
          from: 'disclosure-alerts@tdooner.com',
          to: 'tomdooner@gmail.com',
          subject: "New Campaign Disclosure filings on #{@date}",
          html: email_html
        )
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
