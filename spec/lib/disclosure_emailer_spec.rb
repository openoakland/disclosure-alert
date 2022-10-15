require 'rails_helper'

describe DisclosureEmailer do
  describe '#send_email' do
    let(:today) { Date.parse('2022-10-01') }
    let(:subscribed_agency) { NetfileAgency.coak }
    let(:filing_agency) { NetfileAgency.coak }
    let!(:subscriber) do
      AlertSubscriber.create(
        email: 'test@example.com',
        confirmed_at: Time.now,
        netfile_agency: subscribed_agency,
      )
    end
    let(:filed_at) { today.beginning_of_day.change(hour: 10) }
    let!(:filing) { Filing.create(filer_id: 123, filed_at: filed_at, form: 30, netfile_agency: filing_agency) }
    let!(:valid_filing) { Filing.create(filer_id: 123, filed_at: today.beginning_of_day.change(hour: 10), form: 30, netfile_agency: subscribed_agency) }

    subject { described_class.new(today).send_email }

    before do
      allow(AlertMailer).to receive(:daily_alert).and_return(double(deliver_now: nil))
      allow_any_instance_of(DisclosureEmailer).to receive(:puts)
    end

    context 'with a filing for the appropriate date and agency' do
      it 'includes that filing' do
        subject
        expect(AlertMailer)
          .to have_received(:daily_alert)
          .with(subscriber, today, include(filing), anything)
      end
    end

    context 'when the filing is for a different date' do
      let(:filed_at) { today - 1.day }

      it 'excludes the filing' do
        subject
        expect(AlertMailer)
          .to have_received(:daily_alert)
          .with(subscriber, today, exclude(filing), anything)
      end
    end

    context 'when the filing is for a different agency' do
      let(:filing_agency) { NetfileAgency.sfo }

      it 'excludes the filing' do
        subject
        expect(AlertMailer)
          .to have_received(:daily_alert)
          .with(subscriber, today, exclude(filing), anything)
        expect(AlertMailer)
          .not_to have_received(:daily_alert)
          .with(subscriber, today, include(filing), anything)
      end
    end
  end
end
