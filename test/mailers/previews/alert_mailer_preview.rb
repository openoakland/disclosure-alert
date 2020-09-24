# frozen_string_literal: true

class AlertMailerPreview < ActionMailer::Preview
  def daily_alert
    AlertMailer.daily_alert(
      find_or_create_subscriber,
      Date.yesterday,
      Filing.order(filed_at: :desc).first(30),
      notice: 'A notice to the user would appear here.',
    )
  end

  private

  def find_or_create_subscriber
    AlertSubscriber
      .where(email: 'test+preview@example.com')
      .first_or_create
  end
end
