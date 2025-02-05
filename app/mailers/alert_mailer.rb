# frozen_string_literal: true

# Mailer for the daily alerts
class AlertMailer < ApplicationMailer
  layout 'mailer'

  def daily_alert(alert_subscriber, date_or_date_range, filings, notice)
    @alert_subscriber = alert_subscriber
    @forms = Forms.from_filings(filings)
    @email_notice = notice

    subject_date =
      if date_or_date_range.is_a?(Date)
        "on #{date_or_date_range}"
      else
        start_date = date_or_date_range.min.to_date
        end_date = date_or_date_range.max.to_date

        "between #{start_date} and #{end_date}"
      end

    mail(
      to: @alert_subscriber.email,
      from: 'Open Disclosure Alert <alert@opendisclosure.io>',
      subject: "New Campaign Disclosure filings #{subject_date}",
    )
  end
end
