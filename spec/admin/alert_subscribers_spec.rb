# frozen_string_literal: true
#
require 'rails_helper'

RSpec.describe 'Admin AlertSubscribers Page', type: :request do
  let(:admin) { AdminUser.create!(email: 'test@example.com', password: 'superSecur3') }
  let!(:alert_subscriber) do
    AlertSubscriber.create!(
      email: 'subscriber@example.com',
      confirmed_at: Time.now
    )
  end

  before do
    sign_in admin
    get admin_alert_subscribers_path
  end

  subject { response }

  it 'renders successfully' do
    expect(subject).to be_successful
    expect(subject.body).to include(alert_subscriber.email)
  end
end
