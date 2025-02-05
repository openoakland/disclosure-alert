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
          .daily_alert(subscriber, date_range_for_subscriber(subscriber), filings, notices)
          .deliver_now
      end
    end
  end

  private

  def filings_for_subscriber(alert_subscriber)
    date_or_range = date_range_for_subscriber(alert_subscriber)

    filings = Filing.where(netfile_agency: alert_subscriber.netfile_agency)

    if date_or_range.is_a?(Date)
      filings.filed_on_date(date_or_range)
    else
      filings.filed_in_date_range(date_or_range)
    end
  end

  def notices_for_subscriber(alert_subscriber)
    Notice.where(date: date_range_for_subscriber(alert_subscriber)).order(date: :desc).first
  end

  def date_range_for_subscriber(alert_subscriber)
    case alert_subscriber.subscription_frequency
    when 'daily'
      @date
    when 'weekly'
      return unless @date.sunday?

      @date.all_week
    end
  end
end
