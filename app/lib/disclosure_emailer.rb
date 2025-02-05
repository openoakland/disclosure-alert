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

      puts '==================================================================='
      puts "Emailing to #{subscribers.count} subscribers of #{agency.shortcut}:"
      puts '==================================================================='

      subscribers.find_each do |subscriber|
        filings = filings_for_subscriber(subscriber)
        notices = notices_for_subscriber(subscriber)
        next if filings.none?

        AlertMailer
          .daily_alert(subscriber, @date, filings, notices)
          .deliver_now
      end
    end
  end

  private

  def filings_for_subscriber(alert_subscriber)
    Filing
      .where(netfile_agency: alert_subscriber.netfile_agency)
      .filed_in_date_range(date_range_for_subscriber(alert_subscriber))
  end

  def notices_for_subscriber(alert_subscriber)
    Notice.find_by(date: @date)
  end

  def date_range_for_subscriber(alert_subscriber)
    case alert_subscriber.subscription_frequency
    when 'daily'
      @date.all_day
    when 'weekly'
      return unless @date.sunday?

      @date.all_week
    end
  end
end
