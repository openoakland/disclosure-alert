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
    )
  end

  describe '#daily_alert' do
    let(:alert_subscriber) { AlertSubscriber.create(email: 'tomdooner+test@gmail.com') }
    let(:date) { Date.yesterday }
    let(:filings_in_date_range) do
      [
        create_filing(id: 1),
        create_filing(id: 2),
        create_filing(id: 3),
      ]
    end

    subject { described_class.daily_alert(alert_subscriber, date, filings_in_date_range) }

    it 'renders' do
      expect(subject.body.encoded).to include(filings_in_date_range.first.filer_name)
    end
  end
end
