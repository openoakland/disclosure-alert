# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AlertSubscribersController do
  render_views

  describe '#new' do
    it { expect(get(:new)).to be_successful }
  end

  describe '#create' do
    let(:valid_email) { 'tomdooner+valid@gmail.com' }
    let(:invalid_email) { 'tomdooner+invalid' }
    let(:params) { { alert_subscriber: { email: email } } }

    subject { post :create, params: params }

    describe 'with a valid email' do
      let(:email) { valid_email }

      it 'creates an AlertSubscriber' do
        expect { subject }
          .to(change { AlertSubscriber.count }.by(1))

        subscriber = AlertSubscriber.last
        expect(subscriber.email).to eq(email)
        expect(subscriber.token).to be_present
        expect(subscriber.confirmed_at).to be_nil
        expect(subscriber.unsubscribed_at).to be_nil
      end

      it 'sends a AlertSubscriberMailer.confirm email' do
        subject
        expect(ActionMailer::Base.deliveries).not_to be_empty
        expect(ActionMailer::Base.deliveries.last.to).to eq([email])
      end
    end

    describe 'with an invalid email' do
      let(:email) { invalid_email }

      it 'does not create an AlertSubscriber' do
        expect { subject }
          .not_to(change { AlertSubscriber.count })
      end

      it 'renders an error message' do
        subject
        expect(response.body).to include('Email is invalid')
      end
    end
  end

  describe '#edit' do
    let(:alert_subscriber) { AlertSubscriber.create(email: 'tomdooner+test@gmail.com') }
    let(:request_token) { nil }

    subject { get :edit, params: { id: alert_subscriber.id, token: request_token } }

    describe 'with a valid token' do
      let(:request_token) { alert_subscriber.token }

      it { expect(subject).to be_successful }
    end

    describe 'with an invalid token' do
      let(:request_token) { 'foo bar baz' }

      it { expect(subject).to be_redirect }
    end
  end

  describe '#destroy' do
    let!(:alert_subscriber) { AlertSubscriber.create(email: 'tomdooner+test@gmail.com') }
    let(:request_token) { nil }

    subject { post :destroy, params: { id: alert_subscriber.id, token: request_token } }

    describe 'with a valid token' do
      let(:request_token) { alert_subscriber.token }
      it { expect(subject).to redirect_to(root_url) }

      it 'marks the object as unsubscribed' do
        subject
        expect(alert_subscriber.reload.unsubscribed_at)
          .not_to be_nil
      end
    end

    describe 'with an invalid token' do
      let(:request_token) { 'foo bar baz' }

      it { expect(subject).to be_redirect }
      it { expect { subject }.not_to(change { AlertSubscriber.subscribed.count }) }
    end
  end

  describe '#confirm' do
    render_views

    let!(:alert_subscriber) { AlertSubscriber.create(email: 'tomdooner+test@gmail.com') }
    let(:request_token) { nil }

    subject { post :confirm, params: { id: alert_subscriber.id, token: request_token } }

    describe 'with a valid token' do
      let(:request_token) { alert_subscriber.token }

      it { expect(subject).to be_success }

      it 'marks the object as confirmed' do
        expect { subject }.to change { AlertSubscriber.unconfirmed.count }.by(-1)
        expect(alert_subscriber.reload.confirmed_at)
          .not_to be_nil
      end
    end

    describe 'with an invalid token' do
      let(:request_token) { 'foo bar baz' }

      it { expect(subject).to be_redirect }
      it { expect { subject }.not_to(change { AlertSubscriber.unconfirmed.count }) }
    end
  end
end
