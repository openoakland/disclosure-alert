require 'rails_helper'

describe DisclosureEmailer do
  describe '#send_email' do
    let(:yesterday) { Date.parse('2022-10-01') }
    let(:subscribed_agency) { NetfileAgency.coak }
    let(:filing_agency) { NetfileAgency.coak }
    let!(:subscriber) do
      AlertSubscriber.create(
        email: 'test@example.com',
        confirmed_at: Time.now,
        netfile_agency: subscribed_agency,
        subscription_frequency: 'daily'
      )
    end
    let(:filed_at) { yesterday.beginning_of_day.change(hour: 10) }
    let!(:filing) { Filing.create(filer_id: 123, filed_at: filed_at, form: 30, netfile_agency: filing_agency) }
    let!(:valid_filing) { Filing.create(filer_id: 123, filed_at: yesterday.beginning_of_day.change(hour: 10), form: 30, netfile_agency: subscribed_agency) }

    subject { described_class.new(yesterday).send_email }

    before do
      allow(AlertMailer).to receive(:daily_alert).and_return(double(deliver_now: nil))
      allow_any_instance_of(DisclosureEmailer).to receive(:puts)
    end

    context 'with a filing for the appropriate date and agency' do
      it 'includes that filing' do
        subject
        expect(AlertMailer)
          .to have_received(:daily_alert)
          .with(subscriber, yesterday)
      end
    end

    context 'when the AlertMailer raises NoFilingsToSend' do
      before do
        allow(AlertMailer).to receive(:daily_alert).and_raise(AlertMailer::NoFilingsToSend)
      end

      it 'catches the error and outputs a message' do
        expect_any_instance_of(DisclosureEmailer)
          .to receive(:puts)
          .with(/Failed to send:/)

        expect {
          subject
        }.not_to raise_error

        expect(AlertMailer)
          .to have_received(:daily_alert)
          .with(subscriber, yesterday)
      end
    end
  end
end
