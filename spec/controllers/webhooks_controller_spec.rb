# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebhooksController do
  describe '#mailgun' do
    let(:subscriber) { AlertSubscriber.create(email: 'test@example.com') }
    let(:params) do
      {
        'event-data' => {
          'recipient' => subscriber.email,
          'event' => event,
          'timestamp' => Date.new(2020, 2, 1).to_time.to_f,
          'id' => SecureRandom.hex,
          'severity' => severity,
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
        token: token
      }
    end
    let(:severity) { nil }

    subject { post :mailgun, params: params }

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
  end
end
