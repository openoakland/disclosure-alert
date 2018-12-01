class AlertMailer < ApplicationMailer
  layout 'mailer'
  track open: true, click: true

  def daily_alert(alert_subscriber, date, filings_in_date_range)
    track user: alert_subscriber

    @alert_subscriber = alert_subscriber
    @filings = filings_in_date_range
    @date = date

    mail(
      to: @alert_subscriber.email,
      from: 'disclosure-alerts@tdooner.com',
      subject: "New Campaign Disclosure filings on #{@date}",
    )
  end
end
