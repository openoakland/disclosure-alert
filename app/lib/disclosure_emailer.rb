require 'mailgun-ruby'
require 'haml'
require 'premailer'

class DisclosureEmailer
  def initialize(date)
    @date = date
  end

  def send_email
    NetfileAgency.each_supported_agency do |agency|
      subscribers = AlertSubscriber.subscribed.where(netfile_agency: agency)
      filings = filings_in_date_range(agency)

      puts '==================================================================='
      puts "Emailing to #{subscribers.count} subscribers of #{agency.shortcut}:"
      puts
      puts "Total filings in date range: #{filings.length}"
      puts '==================================================================='
      return if filings.none?

      subscribers.find_each do |subscriber|
        AlertMailer
          .daily_alert(subscriber, @date, filings, notices_in_date_range)
          .deliver_now
      end
    end
  end

  private

  def filings_in_date_range(agency)
    Filing.filed_on_date(@date).where(netfile_agency: agency)
  end

  def notices_in_date_range
    Notice.find_by(date: @date)
  end
end
