# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AlertSubscribersController do
  render_views

  describe '#new' do
    it { expect(get(:new)).to be_successful }

    it "does not include links to preview alert emails when there are no filings" do
      get :new
      expect(response.body).not_to include(/See.*for examples/)
    end

    context "when there are filings yesterday" do
      before do
        Filing.create(netfile_agency: NetfileAgency.coak, filed_at: Date.yesterday)
      end

      it "allows previewing today's email" do
        get :new
        expect(response.body).to include(/See.*today&#39;s.*for examples/m)
        expect(response.body).not_to include(/See.*yesterday&#39;s.*for examples/m)
      end
    end

    context "when there are filings two days ago" do
      before do
        Filing.create(netfile_agency: NetfileAgency.coak, filed_at: Date.yesterday - 1)
      end

      it "allows previewing yesterday's email" do
        get :new
        expect(response.body).to include(/See.*yesterday&#39;s.*for examples/m)
        expect(response.body).not_to include(/See.*today&#39;s.*for examples/m)
      end
    end

    context "when there are filings from yesterday and two days ago" do
      before do
        Filing.create(netfile_agency: NetfileAgency.coak, filed_at: Date.yesterday)
        Filing.create(netfile_agency: NetfileAgency.coak, filed_at: Date.yesterday - 1)
      end

      it "allows previewing both today's and yesterday's email" do
        get :new
        expect(response.body).to include(/See.*today&#39;s.*yesterday&#39;s.*for examples/m)
      end
    end
  end

  describe '#create' do
    let(:valid_email) { 'tomdooner+valid@gmail.com' }
    let(:invalid_email) { 'tomdooner+invalid' }
    let(:params) { { alert_subscriber: { email: email } } }
    let(:email) { valid_email }

    subject { post :create, params: params }

    it 'creates an AlertSubscriber' do
      expect { subject }
        .to(change { AlertSubscriber.count }.by(1))

      subscriber = AlertSubscriber.last
      expect(subscriber.email).to eq(email)
      expect(subscriber.token).to be_present
      expect(subscriber.confirmed_at).to be_nil
      expect(subscriber.unsubscribed_at).to be_nil
      expect(subscriber.netfile_agency).to eq(NetfileAgency.coak)
    end

    it 'sends a AlertSubscriberMailer.confirm email' do
      subject
      expect(ActionMailer::Base.deliveries).not_to be_empty
      expect(ActionMailer::Base.deliveries.last.to).to eq([email])
    end

    describe 'when the user had previously unsubscribed' do
      let!(:previous_subscriber) do
        AlertSubscriber.create(
          email: email,
          netfile_agency: NetfileAgency.coak,
          unsubscribed_at: unsubscribe_date,
          confirmed_at: 11.days.ago
        )
      end
      let!(:admin) { AdminUser.create!(email: 'test@example.com', password: 'superSecur3') }
      let(:unsubscribe_date) { 10.days.ago }

      it 're-subscribes them by clearing the unsubscribe timestamp' do
        expect { subject }
          .to change { previous_subscriber.reload.unsubscribed_at }
          .from(within(1.second).of(unsubscribe_date))
          .to(nil)

        expect(previous_subscriber.confirmed_at).to eq(nil)

        new_comment = ActiveAdmin::Comment.last
        expect(new_comment).to have_attributes(
          body: /Resubscribed/
        )
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
    let(:alert_subscriber) { AlertSubscriber.create(email: 'tomdooner+test@gmail.com', netfile_agency: NetfileAgency.coak) }
    let(:request_token) { nil }

    subject { get :edit, params: { id: alert_subscriber.id, token: request_token } }

    describe 'with a valid token' do
      render_views

      let(:request_token) { alert_subscriber.token }

      it { expect(subject).to be_successful }
    end

    describe 'with an invalid token' do
      let(:request_token) { 'foo bar baz' }

      it { expect(subject).to be_redirect }
    end
  end

  describe "#update" do
    let!(:alert_subscriber) { AlertSubscriber.create(email: 'tomdooner+test@gmail.com', netfile_agency: NetfileAgency.coak) }
    let(:valid_params) do
      {
        id: alert_subscriber.id,
        token: alert_subscriber.token,
        alert_subscriber: {
          subscription_frequency: 'weekly'
        }
      }
    end

    subject { post :update, params: valid_params }

    it 'updates the attributes as expected and redirects back' do
      expect { subject }
        .to change { alert_subscriber.reload.subscription_frequency }
        .from('daily').to('weekly')

      expect(response).to redirect_to(edit_alert_subscriber_path(alert_subscriber, token: alert_subscriber.token))
    end
  end

  describe '#destroy' do
    let!(:alert_subscriber) { AlertSubscriber.create(email: 'tomdooner+test@gmail.com', netfile_agency: NetfileAgency.coak) }
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

    let!(:alert_subscriber) { AlertSubscriber.create(email: 'tomdooner+test@gmail.com', netfile_agency: NetfileAgency.coak) }
    let(:request_token) { nil }

    subject { post :confirm, params: { id: alert_subscriber.id, token: request_token } }

    describe 'with a valid token' do
      let(:request_token) { alert_subscriber.token }

      it { expect(subject).to be_successful }

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
