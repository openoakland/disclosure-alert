class AlertMailerPreview < ActionMailer::Preview
  def daily_alert
    AlertMailer.daily_alert(
      AlertSubscriber.new(email: 'tomdooner+test@gmail.com'),
      Date.yesterday,
      Filing.last(10)
    )
  end
end
