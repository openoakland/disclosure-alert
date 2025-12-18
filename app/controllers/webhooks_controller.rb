class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_mailgun_signature

  UNSUBSCRIBE_THRESHOLD = 3 # failures, within...
  UNSUBSCRIBE_LOOKBACK = 1.month

  # Never unsubscribe these user IDs for 'failed' events. This is super hacky
  # but I'd rather try a narrow blocklist like this than add a column to the
  # database just for this.
  NEVER_UNSUBCRIBE_SUBSCRIBER_IDS = [35]

  def mailgun
    data = params[:'event-data']
    recipient = data[:recipient]
    event = data[:event]
    message = data[:message]

    if event == 'unsubscribed' || event == 'complained'
      handle_unsubscribe(recipient, event)
    elsif event == 'failed' && data[:severity] == 'permanent'
      handle_bounced(message[:headers]['message-id'])
      possibly_unsubscribe_recipient(recipient, event)
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

  def handle_bounced(message_id)
    message = SentMessage.find_by(message_id: message_id)
    if message
      message.touch(:bounced_at)
    else
      Rails.logger.warn "Got permanent failure event for invalid Message ID: #{message}"
    end
  end

  def handle_unsubscribe(recipient, event)
    # Unsubscribe the user
    subscribers = AlertSubscriber.subscribed.where(email: recipient)
    # Leave a note in the admin interface
    subscribers.find_each do |subscriber|
      create_comment(subscriber, <<~BODY)
        Unsubscribed via Mailgun webhook: #{event}
      BODY
    end
    subscribers.update_all(unsubscribed_at: Time.now)
  end

  def possibly_unsubscribe_recipient(recipient, event)
    subscribers = AlertSubscriber.subscribed.where(email: recipient)
    subscribers.find_each do |subscriber|
      previous_failure_count = subscriber.sent_messages.bounced.where('sent_at > ?', UNSUBSCRIBE_LOOKBACK.ago).count
      next unless previous_failure_count >= UNSUBSCRIBE_THRESHOLD

      if NEVER_UNSUBCRIBE_SUBSCRIBER_IDS.include?(subscriber.id)
        create_comment(subscriber, <<~BODY)
          Would have unsubscribed for #{UNSUBSCRIBE_THRESHOLD} failures (event: #{event}) within lookback period, but didn't because ID is in NEVER_UNSUBCRIBE_SUBSCRIBER_IDS.
        BODY
      else
        create_comment(subscriber, <<~BODY)
          Unsubscribed for #{UNSUBSCRIBE_THRESHOLD} failures (event: #{event}) within lookback period.
        BODY

        subscriber.touch(:unsubscribed_at)
      end
    end
  end

  def verify_mailgun_signature
    signature_params = params[:signature]
    return head :unauthorized unless signature_params.present?

    digest = OpenSSL::Digest::SHA256.new
    data = [signature_params[:timestamp], signature_params[:token]].join
    is_valid = signature_params[:signature] == OpenSSL::HMAC.hexdigest(digest, ENV['MAILGUN_SIGNING_KEY'], data)

    return head :unauthorized unless is_valid
  end

  def create_comment(subscriber, body)
    ActiveAdmin::Comment.create(
      resource: subscriber,
      author: AdminUser.first,
      namespace: 'admin',
      body: body,
    )
  end
end
