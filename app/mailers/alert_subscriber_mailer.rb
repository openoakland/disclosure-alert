# frozen_string_literal: true

# Emails built around the process of subscribing to alerts.
class AlertSubscriberMailer < ApplicationMailer
  layout 'mailer'

  def confirm(alert_subscriber)
    @alert_subscriber = alert_subscriber

    mail(
      to: @alert_subscriber.email,
      from: 'Open Disclosure Team <tom@opendisclosure.io>',
      subject: 'Confirm your subscription to Open Disclosure Alerts',
    )
  end

  def subscription_confirmed(alert_subscriber)
    @alert_subscriber = alert_subscriber

    mail(
      to: @alert_subscriber.email,
      bcc: 'tomdooner@gmail.com',
      from: 'Tom Dooner, Open Disclosure Team <tom@opendisclosure.io>',
      subject: 'Welcome to Open Disclosure Alerts!',
    )
  end
end
