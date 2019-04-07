class AlertMailerPreview < ActionMailer::Preview
  def daily_alert
    AlertMailer.daily_alert(
      AlertSubscriber.first,
      Date.yesterday,
      Filing.last(10)
    )
  end
end