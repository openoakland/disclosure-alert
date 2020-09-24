# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AlertMailer do
  def fppc_460_contents
    [
      { 'form_Type' => 'F460', 'line_Item' => '5', 'amount_A' => 40843.0 },
      { 'form_Type' => 'F460', 'line_Item' => '11', 'amount_A' => 20000.2 },
    ]
  end

  def create_filing(id: 123_123, filer_id: 222_222, contents: fppc_460_contents)
    Filing.create(
      id: id,
      filer_id: filer_id,
      filer_name: 'Foo Bar Baz for City Council 2010',
      title: 'FPPC Form 460',
      filed_at: 1.day.ago,
      amendment_sequence_number: '0',
      amended_filing_id: nil,
      form: 30, # FPPC 460
      contents: contents,
    ).tap do |filing|
      ElectionCommittee.create(
        name: 'Foo Bar for City Council 2010',
        fppc_id: filing.filer_id,
      )
    end
  end

  describe '#daily_alert' do
    let(:alert_subscriber) { AlertSubscriber.create(email: 'tomdooner+test@gmail.com') }
    let(:date) { Date.new(2020, 9, 1) }
    let(:filings_in_date_range) do
      [
        create_filing(id: 1),
        create_filing(id: 2),
        create_filing(id: 3),
      ]
    end

    subject { described_class.daily_alert(alert_subscriber, date, filings_in_date_range) }

    it 'renders' do
      expect(subject.subject).to include('filings on 2020-09-01')
      expect(subject.body.encoded).to include(filings_in_date_range.first.filer_name)
      expect(subject.body.encoded).to include('View Contributions')
    end

    context 'when giving a date range instead of a single date' do
      let(:alert_subscriber) { AlertSubscriber.create(email: 'tomdooner+test@gmail.com') }
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
  end
end
