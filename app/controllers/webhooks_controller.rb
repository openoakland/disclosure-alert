class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_mailgun_signature

  def mailgun
    data = params[:'event-data']
    recipient = data[:recipient]
    event = data[:event]

    if event == 'unsubscribed' ||
       event == 'complained' ||
       (event == 'failed' && data[:severity] == 'permanent')
      # Unsubscribe the user
      subscribers = AlertSubscriber.where(email: recipient)
      subscribers.update_all(unsubscribed_at: Time.now)
      # Leave a note in the admin interface
      subscribers.find_each do |subscriber|
        ActiveAdmin::Comment.create(
          resource: subscriber,
          author: AdminUser.first,
          namespace: 'admin',
          body: <<~BODY,
            Unsubscribed via Mailgun webhook: #{event}
          BODY
        )
      end
    end
  end

  private

  def verify_mailgun_signature
    signature_params = params[:signature]
    return head :unauthorized unless signature_params.present?

    digest = OpenSSL::Digest::SHA256.new
    data = [signature_params[:timestamp], signature_params[:token]].join
    is_valid = signature_params[:signature] == OpenSSL::HMAC.hexdigest(digest, ENV['MAILGUN_SIGNING_KEY'], data)

    return head :unauthorized unless is_valid
  end
end
