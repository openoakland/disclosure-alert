class AlertSubscriberPreview < ActionMailer::Preview
  def subscription_created
    AlertSubscriberMailer.subscription_confirmed(
      AlertSubscriber.first
    )
  end
end
