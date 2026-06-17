# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Netfile::Client do
  subject(:client) { described_class.new }

  describe '#filings_by_date' do
    let(:start_date) { Date.new(2026, 6, 1) }
    let(:end_date)   { Date.new(2026, 6, 16) }

    def stub_api(filings:, total_count: nil)
      body = JSON.generate(
        'filings'    => filings,
        'totalCount' => total_count || filings.length,
      )
      response = double('response', code: '200', body: body)
      http = double('http')
      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(http).to receive(:request).and_return(response)
    end

    context 'with filings in the date range' do
      let(:filing_json) do
        {
          'id'             => '216861492',
          'formName'       => 'FPPC Form 497',
          'filerName'      => 'Test Committee',
          'filingDate'     => '2026-06-04T17:16:23.22+00:00',
          'sequenceNumber' => '0',
        }
      end

      before { stub_api(filings: [filing_json]) }

      it 'returns the filings' do
        result = client.filings_by_date(start_date, end_date)
        expect(result.length).to eq(1)
      end

      it 'includes filerName' do
        result = client.filings_by_date(start_date, end_date)
        expect(result.first['filerName']).to eq('Test Committee')
      end

      it 'includes filingDate' do
        result = client.filings_by_date(start_date, end_date)
        expect(result.first['filingDate']).to be_present
      end
    end

    context 'with no filings in the date range' do
      before { stub_api(filings: []) }

      it 'returns an empty array' do
        expect(client.filings_by_date(start_date, end_date)).to eq([])
      end
    end

    context 'with multiple pages' do
      let(:page1_filings) { Array.new(100) { |i| { 'id' => i.to_s, 'filerName' => "Committee #{i}", 'formName' => 'FPPC 460', 'filingDate' => '2026-06-01T00:00:00Z', 'sequenceNumber' => '0' } } }
      let(:page2_filings) { [{ 'id' => '100', 'filerName' => 'Committee 100', 'formName' => 'FPPC 460', 'filingDate' => '2026-06-01T00:00:00Z', 'sequenceNumber' => '0' }] }

      before do
        http = double('http')
        allow(Net::HTTP).to receive(:start).and_yield(http)

        page1_body = JSON.generate('filings' => page1_filings, 'totalCount' => 101)
        page2_body = JSON.generate('filings' => page2_filings, 'totalCount' => 101)

        allow(http).to receive(:request).and_return(
          double('response', code: '200', body: page1_body),
          double('response', code: '200', body: page2_body),
        )
      end

      it 'fetches all pages and returns all filings' do
        result = client.filings_by_date(start_date, end_date)
        expect(result.length).to eq(101)
      end
    end

    context 'when the API returns an error' do
      before do
        response = double('response', code: '500', message: 'Internal Server Error')
        http = double('http')
        allow(Net::HTTP).to receive(:start).and_yield(http)
        allow(http).to receive(:request).and_return(response)
      end

      it 'raises an error' do
        expect { client.filings_by_date(start_date, end_date) }.to raise_error(RuntimeError, /Request failed/)
      end
    end
  end
end
