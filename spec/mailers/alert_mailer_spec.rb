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

  def create_filing(id: 123_123, form: 30, filer_id: 222_222, contents: fppc_460_contents)
    Filing.create(
      id: id,
      filer_id: filer_id,
      filer_name: 'Foo Bar Baz for City Council 2010',
      title: 'FPPC Form 460',
      filed_at: 1.day.ago,
      amendment_sequence_number: '0',
      amended_filing_id: nil,
      netfile_agency: NetfileAgency.coak,
      form: form, # Form 30 = FPPC 460
      contents: contents,
    ).tap do |filing|
      ElectionCommittee.create(
        name: 'Foo Bar for City Council 2010',
        fppc_id: filing.filer_id,
      )
    end
  end

  def create_filings_to_combine(id: 333_333)
    [
      Filing.create(
        id: id,
        filer_id: 333_333,
        filer_name: 'Oakland for better Oaklanders',
        title: 'FPPC Form 496',
        filed_at: 1.day.ago,
        amendment_sequence_number: '0',
        amended_filing_id: nil,
        netfile_agency: NetfileAgency.coak,
        form: 36, # FPPC 496
        contents: fppc_496_contents('Candidate A'),
      ),
      Filing.create(
        id: id + 1,
        filer_id: 333_333,
        filer_name: 'Oakland for better Oaklanders',
        title: 'FPPC Form 496',
        filed_at: 1.day.ago,
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
    let(:date) { Date.new(2020, 9, 1) }
    let(:filings_in_date_range) do
      [
        create_filing(id: 1),
        create_filing(id: 2),
        create_filing(id: 3),
        create_filing(id: 4, form: 39, contents: fppc_497_contents),
      ] + create_filings_to_combine
    end
    let(:notice) { nil }

    subject { described_class.daily_alert(alert_subscriber, date, filings_in_date_range, notice) }

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

    context 'when giving a date range instead of a single date' do
      let(:alert_subscriber) { AlertSubscriber.create(email: 'tomdooner+test@gmail.com', netfile_agency: NetfileAgency.coak) }
      let(:date) { Date.new(2020, 9, 1)..Date.new(2020, 9, 20) }
      let(:filings_in_date_range) do
        [
          create_filing(id: 1),
          create_filing(id: 2),
          create_filing(id: 3),
        ]
      end

      it 'renders' do
        expect(subject.subject).to include('between 2020-09-01 and 2020-09-20')
        expect(subject.body.encoded).to include(filings_in_date_range.first.filer_name)
      end
    end

    context 'when a notice is in effect for the email' do
      let(:notice_creator) { AdminUser.create(email: 'tomdooner@example.com') }
      let(:notice) { Notice.create!(creator: notice_creator, body: notice_body, date: date) }
      let(:notice_body) { 'Eat your <strong>fruits</strong> and vegetables!' }

      it 'renders the notice in the email' do
        expect(subject.body.encoded).to include(notice_body)
      end
    end
  end
end
