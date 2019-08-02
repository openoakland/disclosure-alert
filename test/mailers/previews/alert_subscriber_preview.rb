class AlertSubscriberPreview < ActionMailer::Preview
  def subscription_created
    AlertSubscriberMailer.subscription_created(
      AlertSubscriber.first
    )
  end
end
