require 'rails_helper'

RSpec.describe 'admin:backfill_sent_messages' do
  let(:subscriber) { AlertSubscriber.create(email: 'test@example.com', netfile_agency: NetfileAgency.coak) }
  let(:sent_at) { 3.days.ago }
  let(:opened_at) { 2.days.ago }
  let!(:ahoy_message) do
    Ahoy::Message.create(
      user: subscriber,
      to: 'test@example.com',
      mailer: 'AlertMailer#daily_alert',
      subject: "New Campaign Disclosure filings on 2022-10-18",
      token: 'foo',
      sent_at: sent_at,
      opened_at: opened_at
    )
  end

  before(:all) do
    Rails.application.load_tasks
  end

  it 'transfers data over properly' do
    expect do
      Rake::Task['admin:backfill_sent_messages'].invoke
    end.to change(SentMessage, :count).by(1)

    created = SentMessage.last
    expect(created).to have_attributes(
      alert_subscriber: subscriber,
      message_id: 'foo',
      sent_at: within(1.second).of(sent_at),
      opened_at: within(1.second).of(opened_at),
      clicked_at: nil,
      mailer: 'AlertMailer#daily_alert',
    )
  end
end
