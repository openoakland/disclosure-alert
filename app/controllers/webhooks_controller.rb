class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_mailgun_signature

  def mailgun
    data = params[:'event-data']
    recipient = data[:recipient]
    event = data[:event]
    message = data[:message]

    if event == 'unsubscribed' ||
       event == 'complained' ||
       (event == 'failed' && data[:severity] == 'permanent')
      handle_unsubscribe(recipient, event)
    elsif event == 'opened'
      handle_opened(message[:headers]['message-id'])
    elsif event == 'clicked'
      handle_clicked(message[:headers]['message-id'])
    end
  end

  private

  def handle_opened(message_id)
    message = SentMessage.find_by(message_id: message_id)
    if message
      message.touch(:opened_at)
    else
      Rails.logger.warn "Got opened event for invalid Message ID: #{message}"
    end
  end

  def handle_clicked(message_id)
    message = SentMessage.find_by(message_id: message_id)
    if message
      message.touch(:clicked_at)
    else
      Rails.logger.warn "Got clicked event for invalid Message ID: #{message}"
    end
  end

  def handle_unsubscribe(recipient, event)
    # Unsubscribe the user
    subscribers = AlertSubscriber.subscribed.where(email: recipient)
    # Leave a note in the admin interface
    subscribers.find_each do |subscriber|
      comment = ActiveAdmin::Comment.create(
        resource: subscriber,
        author: AdminUser.first,
        namespace: 'admin',
        body: <<~BODY,
          Unsubscribed via Mailgun webhook: #{event}
        BODY
      )
    end
    subscribers.update_all(unsubscribed_at: Time.now)
  end

  def verify_mailgun_signature
    signature_params = params[:signature]
    return head :unauthorized unless signature_params.present?

    digest = OpenSSL::Digest::SHA256.new
    data = [signature_params[:timestamp], signature_params[:token]].join
    is_valid = signature_params[:signature] == OpenSSL::HMAC.hexdigest(digest, ENV['MAILGUN_SIGNING_KEY'], data)

    return head :unauthorized unless is_valid
  end
end
