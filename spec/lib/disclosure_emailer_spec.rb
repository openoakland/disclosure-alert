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
          .with(subscriber, yesterday, include(filing), anything)
      end
    end

    context 'when the filing is for a different date' do
      let(:filed_at) { yesterday - 1.day }

      it 'excludes the filing' do
        subject
        expect(AlertMailer)
          .to have_received(:daily_alert)
          .with(subscriber, yesterday, exclude(filing), anything)
      end
    end

    context 'when the filing is for a different agency' do
      let(:filing_agency) { NetfileAgency.sfo }

      it 'excludes the filing' do
        subject
        expect(AlertMailer)
          .to have_received(:daily_alert)
          .with(subscriber, yesterday, exclude(filing), anything)
        expect(AlertMailer)
          .not_to have_received(:daily_alert)
          .with(subscriber, yesterday, include(filing), anything)
      end
    end

    context 'when the subscriber is sent to weekly frequency' do
      before do
        subscriber.update(subscription_frequency: 'weekly')
      end

      context 'on non-Mondays' do
        it 'does not send an email' do
          subject
          expect(AlertMailer)
            .not_to have_received(:daily_alert)
            .with(subscriber, anything, anything, anything)
        end
      end

      context 'on Monday' do
        # When sending Monday's email, yesterday was a Sunday:
        let(:yesterday) { Date.parse('2022-10-02') }
        let(:filed_at) { yesterday - 3.days }

        it 'sends an email including filings from the past week' do
          subject
          expect(AlertMailer)
            .to have_received(:daily_alert)
            .with(subscriber, yesterday, include(filing), anything)
        end
      end
    end
  end
end
