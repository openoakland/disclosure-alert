# frozen_string_literal: true

# Mailer for the daily alerts
class AlertMailer < ApplicationMailer
  layout 'mailer'

  NoFilingsToSend = Class.new(StandardError)

  def daily_alert(alert_subscriber, send_date)
    filings = filings_for_subscriber(alert_subscriber, send_date)
    date_range = date_range_for_subscriber(alert_subscriber, send_date)
    raise NoFilingsToSend.new("No filings for #{alert_subscriber.email} #{date_range_text(date_range)}") if filings.none?

    @alert_subscriber = alert_subscriber
    @forms = Forms.from_filings(filings)
    @email_notice = notices_for_subscriber(alert_subscriber, send_date)
    @upcoming_deadlines = FilingDeadline.future.relevant_to_agency(alert_subscriber.netfile_agency)

    mail(
      to: @alert_subscriber.email,
      from: 'Open Disclosure Alert <alert@opendisclosure.io>',
      subject: "New Campaign Disclosure filings #{date_range_text(date_range)}",
    )
  end

  private

  def filings_for_subscriber(alert_subscriber, send_date)
    date_or_range = date_range_for_subscriber(alert_subscriber, send_date)

    filings = Filing
      .where(netfile_agency: alert_subscriber.netfile_agency)
      .includes(:election_candidates, :election_committee, :amended_filing)

    if date_or_range.is_a?(Date)
      filings.filed_on_date(date_or_range)
    else
      filings.filed_in_date_range(date_or_range)
    end
  end

  def notices_for_subscriber(alert_subscriber, send_date)
    Notice.where(date: date_range_for_subscriber(alert_subscriber, send_date)).order(date: :desc).first
  end

  def date_range_for_subscriber(alert_subscriber, send_date)
    case alert_subscriber.subscription_frequency
    when 'daily'
      send_date
    when 'weekly'
      return unless send_date.sunday?

      send_date.all_week
    end
  end

  def date_range_text(date_or_date_range)
    case date_or_date_range
    when Date
      "on #{date_or_date_range}"
    when nil
      # Partial subscription periods have a `nil` range to filter out all
      # filings and notices. Let's just handle this with a generic message that
      # should never show to users.
      "in subscription period"
    else
      start_date = date_or_date_range.min.to_date
      end_date = date_or_date_range.max.to_date

      "between #{start_date} and #{end_date}"
    end
  end
end
