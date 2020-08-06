# frozen_string_literal: true

# Mailer for the daily alerts
class AlertMailer < ApplicationMailer
  layout 'mailer'

  track open: true, click: true, utm_params: true,
    user: -> { AlertSubscriber.subscribed.find_by(email: message.to.first) }

  def daily_alert(alert_subscriber, date, filings_in_date_range)
    @alert_subscriber = alert_subscriber
    @forms = Forms.from_filings(filings_in_date_range)
    @date = date

    mail(
      to: @alert_subscriber.email,
      from: 'Open Disclosure Alert <alert@opendisclosure.io>',
      subject: "New Campaign Disclosure filings on #{@date}",
    )
  end
end
