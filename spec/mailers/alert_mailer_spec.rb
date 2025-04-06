# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AlertMailer do
  def fppc_460_contents
    [
      { 'form_Type' => 'F460', 'line_Item' => '5', 'amount_A' => 40843.0 },
      { 'form_Type' => 'F460', 'line_Item' => '11', 'amount_A' => 20000.2 },
    ]
  end

  def fppc_496_contents(candidate_name)
    [
      { 'form_Type' => 'F496P3', 'calculated_Amount' => 25_000.0, 'sup_Opp_Cd' => nil, 'tran_NamL' => 'Contributor',
        'tran_Amt1' => 25_000.0, 'cmte_Id' => '1234567', },
      { 'form_Type' => 'F496', 'tran_Dscr' => 'PHONE CALLS', 'calculated_Amount' => 5_830.5,
        'cand_NamL' => candidate_name, 'sup_Opp_Cd' => 'S', 'tran_Amt1' => 5_830.5, 'cmte_Id' => nil, },
    ]
  end

  def fppc_497_contents
    [
      { "form_Type"=>"F497P1", "tran_NamL"=>"One", "calculated_Amount"=>40000.0 },
      { "form_Type"=>"F497P1", "tran_NamL"=>"Two", "calculated_Amount"=>490.0 },
      { "form_Type"=>"F497P1", "tran_NamL"=>"Three", "calculated_Amount"=>327.75 },
      { "form_Type"=>"F497P1", "tran_NamL"=>"Four", "calculated_Amount"=>1805.7 },
      { "form_Type"=>"F497P2", "tran_NamL"=>"Five", "calculated_Amount"=>5872.64 },
      { "form_Type"=>"F497P2", "tran_NamL"=>"Six", "calculated_Amount"=>6185.05 }
    ]
  end

  def create_filing(
    id: 123_123,
    form: 30,
    filer_id: 222_222,
    contents: fppc_460_contents,
    contents_xml: nil,
    filed_at: 1.day.ago,
    netfile_agency: NetfileAgency.coak
  )
    Filing.create!(
      id: id,
      filer_id: filer_id,
      filer_name: "Foo Bar Baz #{id} for City Council 2010",
      title: 'FPPC Form 460',
      filed_at: filed_at,
      amendment_sequence_number: '0',
      amended_filing_id: nil,
      netfile_agency: netfile_agency,
      form: form, # Form 30 = FPPC 460
      contents: contents,
    ).tap do |filing|
      ElectionCommittee.create!(
        name: 'Foo Bar for City Council 2010',
        fppc_id: filing.filer_id,
      )
    end
  end

  def create_filings_to_combine(id: 333_333, filed_at: 1.day.ago)
    [
      Filing.create!(
        id: id,
        filer_id: 333_333,
        filer_name: 'Oakland for better Oaklanders',
        title: 'FPPC Form 496',
        filed_at: filed_at,
        amendment_sequence_number: '0',
        amended_filing_id: nil,
        netfile_agency: NetfileAgency.coak,
        form: 36, # FPPC 496
        contents: fppc_496_contents('Candidate A'),
      ),
      Filing.create!(
        id: id + 1,
        filer_id: 333_333,
        filer_name: 'Oakland for better Oaklanders',
        title: 'FPPC Form 496',
        filed_at: filed_at,
        amendment_sequence_number: '0',
        amended_filing_id: nil,
        netfile_agency: NetfileAgency.coak,
        form: 36, # FPPC 496
        contents: fppc_496_contents('Candidate B'),
      ),
    ]
  end

  describe '#daily_alert' do
    let(:alert_subscriber) { AlertSubscriber.create(email: 'tomdooner+test@gmail.com', netfile_agency: NetfileAgency.coak) }
    let(:send_date) { Date.new(2020, 9, 1) } # Tuesday
    let!(:filings_in_date_range) do
      [
        create_filing(id: 1, filed_at: send_date.noon),
        create_filing(id: 2, filed_at: send_date.noon),
        create_filing(id: 3, filed_at: send_date.noon),
        create_filing(id: 4, form: 39, contents: fppc_497_contents, filed_at: send_date.noon),
      ] + create_filings_to_combine(filed_at: send_date.noon)
    end
    let(:notice) { nil }

    subject { described_class.daily_alert(alert_subscriber, send_date) }

    it 'renders' do
      expect(subject.subject).to include('filings on 2020-09-01')
      expect(subject.body.encoded).to include(filings_in_date_range.first.filer_name)
      expect(subject.body.encoded).to include('View Contributions')
    end

    it 'combines similar filings' do
      expect(subject.body.encoded).to include('Combination of 2 FPPC Form 496')
    end

    it 'saves a SentMessage record' do
      expect { @message = subject.deliver_now }
        .to change(SentMessage, :count)
        .by(1)

      last_message = SentMessage.last
      expect(last_message).to have_attributes(
        subject: /New Campaign Disclosure filings/,
        message_id: @message.message_id,
        mailer: 'alert_mailer/daily_alert',
        sent_at: within(1.second).of(Time.current)
      )
    end

    context 'when the subscriber is sent to weekly frequency' do
      let(:alert_subscriber) do
        AlertSubscriber.create(
          email: 'tomdooner+test@gmail.com',
          netfile_agency: NetfileAgency.coak,
          subscription_frequency: 'weekly'
        )
      end
      let!(:filings_in_date_range) do
        [
          create_filing(id: 1, filed_at: send_date - 4.days),
          create_filing(id: 2, filed_at: send_date - 3.days),
          create_filing(id: 3, filed_at: send_date - 2.days),
        ]
      end

      context 'on non-Mondays' do
        it 'returns nothing' do
          expect { subject.deliver_now }.to raise_error(AlertMailer::NoFilingsToSend)
        end
      end

      context 'on Mondays' do
        let(:send_date) do
          # A Sunday, because that means the email is going out on Monday:
          Date.parse('2022-10-02')
        end

        it 'renders' do
          expect(subject.subject).to include('between 2022-09-26 and 2022-10-02')
          expect(subject.body.encoded).to include(filings_in_date_range.first.filer_name)
          expect(subject.body.encoded).to include(filings_in_date_range.second.filer_name)
          expect(subject.body.encoded).to include(filings_in_date_range.third.filer_name)
        end
      end
    end

    context 'when there is a filing that fails to download' do
      let(:filings_in_date_range) do
        [
          create_filing(id: 1, filed_at: send_date.noon),
          create_filing(id: 2, filed_at: send_date.noon, contents: { error: "Net::HTTPInternalServerError", message: "Foo" }),
        ]
      end

      it 'renders' do
        expect(subject.subject).to include('filings on 2020-09-01')
        expect(subject.body.encoded).to include(filings_in_date_range.first.filer_name)
        expect(subject.body.encoded).to include(filings_in_date_range.second.filer_name)
        expect(subject.body.encoded).to include("A NetFile error occurred")
      end
    end

    context 'when a notice is in effect for the email' do
      let(:notice_creator) { AdminUser.create(email: 'tomdooner@example.com') }
      let!(:notice) { Notice.create!(creator: notice_creator, body: notice_body, date: send_date) }
      let(:notice_body) { 'Eat your <strong>fruits</strong> and vegetables!' }

      it 'renders the notice in the email' do
        expect(subject.body.encoded).to include(notice_body)
      end
    end

    context "when there are filings to minimize" do
      let(:minimizable_filings) do
        [
          create_filing(id: 10, form: 7, filed_at: send_date.noon, contents: nil, contents_xml: nil),
          create_filing(id: 11, form: 7, filed_at: send_date.noon, contents: nil, contents_xml: nil),
        ]
      end
      let!(:filings_in_date_range) do
        [
          create_filing(id: 1, filed_at: send_date.noon),
          create_filing(id: 2, filed_at: send_date.noon),
        ] + minimizable_filings
      end

      it "minimizes the filings" do
        expect(subject.body.encoded).to match(
          %r{Additionally, these 2 filings did not appear to contain any significant data:.*#{minimizable_filings.first.filer_name}.*#{minimizable_filings.second.filer_name}}m
        )
      end
    end
  end

  describe "#filings_for_subscriber" do
    let(:alert_subscriber) { AlertSubscriber.create(email: 'tomdooner+test@gmail.com', netfile_agency: NetfileAgency.coak) }
    let(:send_date) { Date.new(2020, 9, 1) }
    let(:filed_at) { send_date.noon }
    let!(:filing) { create_filing(filed_at: filed_at, netfile_agency: filing_agency) }
    let(:filing_agency) { NetfileAgency.coak }

    subject { described_class.new.send(:filings_for_subscriber, alert_subscriber, send_date) }

    it 'returns a filing from the agency within the date range' do
      expect(subject).to include(filing)
    end

    context 'when the filing is for a different date' do
      let(:filed_at) { send_date - 1.day }

      it 'excludes the filing' do
        expect(subject).not_to include(filing)
      end
    end

    context 'when the filing is for a different agency' do
      let(:filing_agency) { NetfileAgency.sfo }

      it 'excludes the filing' do
        expect(subject).not_to include(filing)
      end
    end

    context 'when the subscriber is sent to weekly frequency' do
      before do
        alert_subscriber.update(subscription_frequency: 'weekly')
      end

      context 'on non-Mondays' do
        it 'returns nothing' do
          expect(subject).to be_empty
        end
      end

      context 'on Mondays' do
        let(:send_date) do
          # A Sunday, because that means the email is going out on Monday:
          Date.parse('2022-10-02')
        end
        let(:filed_at) { send_date - 3.days }

        it 'includes filings from the prior week' do
          expect(subject).to include(filing)
        end
      end
    end
  end

  describe "#notices_for_subscriber" do
    let(:alert_subscriber) { AlertSubscriber.create(email: 'tomdooner+test@gmail.com', netfile_agency: NetfileAgency.coak) }
    let(:send_date) { Date.new(2020, 9, 1) }

    subject { described_class.new.send(:notices_for_subscriber, alert_subscriber, send_date) }

    it 'returns nil when there is no notice for that date' do
      expect(subject).to eq(nil)
    end

    context 'when there is a notice for that date' do
      let(:admin_user) { AdminUser.create!(email: 'test@example.com', password: 'foobar') }
      let!(:notice) { Notice.create!(date: send_date, body: "Test notice please ignore", creator: admin_user) }

      it 'includes the notice' do
        expect(subject).to eq(notice)
      end
    end

    context 'when the subscriber is sent to weekly frequency' do
      before do
        alert_subscriber.update(subscription_frequency: 'weekly')
      end

      context 'on non-Mondays' do
        it { expect(subject).to eq(nil) }
      end

      context 'on Mondays' do
        let(:send_date) do
          # A Sunday, because that means the email is going out on Monday:
          Date.parse('2022-10-02')
        end

        let(:admin_user) { AdminUser.create!(email: 'test@example.com', password: 'foobar') }
        let!(:first_notice) { Notice.create!(date: send_date - 3, body: "First notice please ignore", creator: admin_user) }
        let!(:second_notice) { Notice.create!(date: send_date - 2, body: "Second notice please ignore", creator: admin_user) }

        it 'includes the latest notice' do
          expect(subject).to eq(second_notice)
        end
      end
    end
  end
end
