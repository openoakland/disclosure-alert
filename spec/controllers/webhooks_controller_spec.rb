# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebhooksController do
  describe '#mailgun' do
    subject { post :mailgun, params: params }

    let(:subscriber) do
      AlertSubscriber.create(
        email: 'test@example.com',
        confirmed_at: Time.now,
        netfile_agency: NetfileAgency.coak,
      )
    end
    let!(:admin_user) { AdminUser.create(email: 'admin@example.com', password: 'secretpassword') }
    let(:params) do
      {
        'event-data' => {
          'recipient' => subscriber.email,
          'event' => event,
          'timestamp' => Date.new(2020, 2, 1).to_time.to_f,
          'id' => SecureRandom.hex,
          'severity' => severity,
          'message' => {
            'headers' => {
              'message-id' => message_id,
            },
          },
        }.compact,
        'signature' => valid_signature,
      }
    end
    let(:valid_signature) do
      timestamp = Time.now.to_i.to_s
      token = SecureRandom.hex

      {
        signature: OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest::SHA256.new,
          ENV['MAILGUN_SIGNING_KEY'],
          [timestamp, token].join,
        ),
        timestamp: timestamp,
        token: token,
      }
    end
    let(:severity) { nil }
    let(:message_id) { SecureRandom.hex }

    before do
      ENV['MAILGUN_SIGNING_KEY'] ||= SecureRandom.hex
    end

    shared_examples_for 'unsubscribing the user' do
      it 'unsubscribes the user' do
        expect { subject }
          .to change { subscriber.reload.unsubscribed_at }
          .to(instance_of(ActiveSupport::TimeWithZone))
      end
    end

    context 'with an invalid signature' do
      let(:event) { 'unsubscribed' }
      let(:params) { super().merge(signature: {}) }

      it 'return unauthorized' do
        subject
        expect(response.status).to eq(401)
      end
    end

    context 'for an unsubscribe' do
      let(:event) { 'unsubscribed' }
      it_behaves_like 'unsubscribing the user'

      it 'creates an ActiveAdmin::Comment documenting why' do
        expect { subject }
          .to change(ActiveAdmin::Comment, :count)
          .by(1)

        comment = ActiveAdmin::Comment.where(resource: subscriber).last
        expect(comment.body).to include('Unsubscribed via Mailgun webhook')
      end
    end

    context 'for a complaint' do
      let(:event) { 'complained' }
      it_behaves_like 'unsubscribing the user'
    end

    context 'for a temporary failure' do
      let(:event) { 'failed' }
      let(:severity) { 'temporary' }

      it 'does not unsubscribe the user' do
        expect { subject }
          .not_to(change { subscriber.reload.unsubscribed_at })
      end
    end

    context 'for a permanent failure' do
      let(:event) { 'failed' }
      let(:severity) { 'permanent' }
      it_behaves_like 'unsubscribing the user'
    end

    context 'for an open' do
      let(:event) { 'opened' }
      let!(:sent_message) do
        SentMessage.create(
          alert_subscriber: subscriber,
          message_id: message_id,
        )
      end

      it 'updates the opened_at timestamp' do
        expect { subject }
          .to change { sent_message.reload.opened_at }
          .from(nil)
          .to(within(1.second).of(Time.current))
      end
    end

    context 'for a click' do
      let(:event) { 'clicked' }
      let!(:sent_message) do
        SentMessage.create(
          alert_subscriber: subscriber,
          message_id: message_id,
        )
      end

      it 'updates the clicked_at timestamp' do
        expect { subject }
          .to change { sent_message.reload.clicked_at }
          .from(nil)
          .to(within(1.second).of(Time.current))
      end
    end
  end
end
