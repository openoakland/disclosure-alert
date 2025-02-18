# frozen_string_literal: true

class AlertMailerPreview < ActionMailer::Preview
  def daily_alert
    AlertMailer.daily_alert(
      find_or_create_subscriber,
      Date.yesterday,
    )
  end

  def daily_alert_last_week
    AlertMailer.daily_alert(
      find_or_create_subscriber,
      Date.today.last_week.all_week,
    )
  end

  private

  def find_or_create_subscriber
    AlertSubscriber
      .where(email: 'test+preview@example.com')
      .first_or_create
  end
end
