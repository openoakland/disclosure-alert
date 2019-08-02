class AlertSubscriberMailer < ApplicationMailer
  layout 'mailer'

  track open: true, click: true, utm_params: true,
    user: -> { AlertSubscriber.find_by(email: message.to.first) }

  def subscription_created(alert_subscriber)
    @alert_subscriber = alert_subscriber

    mail(
      to: @alert_subscriber.email,
      bcc: 'tomdooner@gmail.com',
      from: 'Tom Dooner, Open Disclosure Team <tom@opendisclosure.io>',
      subject: 'Welcome to Open Disclosure Alerts!',
    )
  end
end
