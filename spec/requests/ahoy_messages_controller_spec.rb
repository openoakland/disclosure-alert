# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ahoy::MessagesController do
  describe '#click' do
    let(:subscriber) do
      AlertSubscriber.create(
        email: 'test@example.com',
        confirmed_at: Time.now,
        netfile_agency: NetfileAgency.coak,
      )
    end
    let(:date) { Date.new(2020, 9, 1) }
    let(:notice) { nil }
    let(:filings_in_date_range) do
      [
        create_filing(id: 1),
        create_filing(id: 2),
        create_filing(id: 3),
      ]
    end

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
        netfile_agency: NetfileAgency.coak,
        form: 30, # FPPC 460
        contents: contents,
      ).tap do |filing|
        ElectionCommittee.create(
          name: 'Foo Bar for City Council 2010',
          fppc_id: filing.filer_id,
        )
      end
    end

    before do
      AlertMailer
        .daily_alert(subscriber, date, filings_in_date_range, notice)
        .deliver_now
    end

    it 'allows the user to click a link in the sent email' do
      sent_email = ActionMailer::Base.deliveries.last
      expect(sent_email).to be_present
      expect(Ahoy::Message.count).to eq(1)

      body = ActionMailer::Base.deliveries.last.html_part.body
      parsed_body = Nokogiri::HTML(body.to_s.force_encoding('ASCII-8BIT'))

      link_url = parsed_body.xpath('//a[contains(text(), "View Filing")]').first.attribute('href').value
      get link_url
      expect(response).to redirect_to(%r{\Ahttps://netfile\.com})
    end
  end
end
