# frozen_string_literal: true

# Mailer for the daily alerts
class AlertMailer < ApplicationMailer
  layout 'mailer'

  def daily_alert(alert_subscriber, date_or_date_range, filings, notice)
    @alert_subscriber = alert_subscriber
    @forms = Forms.from_filings(filings)
    @email_notice = notice

    subject_date = if date_or_date_range.is_a?(Range)
                     "between #{date_or_date_range.min} and #{date_or_date_range.max}"
                   else
                     "on #{date_or_date_range}"
                   end

    mail(
      to: @alert_subscriber.email,
      from: 'Open Disclosure Alert <alert@opendisclosure.io>',
      subject: "New Campaign Disclosure filings #{subject_date}",
    )
  end
end
