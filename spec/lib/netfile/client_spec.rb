# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Netfile::Client do
  include ActiveSupport::Testing::TimeHelpers

  subject(:client) { described_class.new }

  let(:agency) { NetfileAgency.coak }

  # The fixtures are real responses captured from Connect2 on this date, so the
  # clock is pinned to keep the feed-history guard deterministic.
  let(:today) { Date.new(2026, 10, 21) }

  around { |ex| travel_to(today) { ex.run } }

  def fixture(name)
    File.read(Rails.root.join('spec/fixtures/netfile', name))
  end

  # Replaces only the network, so the RSS parsing and the metadata mapping are
  # exercised against the captured responses.
  def stub_netfile(feed: fixture('coak_filing_log.xml'), infos: nil)
    infos ||= {
      '217685109' => fixture('filing_info_217685109.json'),
      '217680684' => fixture('filing_info_217680684.json'),
      '217680490' => fixture('filing_info_217680490.json'),
    }

    allow(client).to receive(:get) do |url, **_kwargs|
      case url
      when %r{/list/filing/rss/COAK}
        feed
      when %r{/filing/info/(\d+)}
        infos.fetch(Regexp.last_match(1)) { raise "no fixture for filing #{Regexp.last_match(1)}" }
      else
        raise "unexpected request: #{url}"
      end
    end
  end

  describe '#filings_by_date' do
    it 'returns filings in the shape Filing.from_json reads' do
      stub_netfile

      filings = client.filings_by_date(today - 7, today, agency)

      expect(filings.length).to eq(3)
      expect(filings.first).to eq(
        'id' => '217685109',
        'filerName' => 'BRINGING OAKLAND TOGETHER YES ON MEASURE EE, SPONSORED BY POWERPAC.ORG',
        'formName' => 'FPPC Form 460 (9/20/2026 - 10/17/2026)',
        'agency' => agency.netfile_id,
        'filingDate' => '2026-10-21T11:16:50.1730000-07:00',
        'sequenceNumber' => 0,
      )
    end

    it 'returns filings that Filing.from_json turns into usable records' do
      stub_netfile

      json = client.filings_by_date(today - 7, today, agency).first
      filing = Filing.from_json(json)

      expect(filing.filer_name).to start_with('BRINGING OAKLAND TOGETHER')
      expect(filing.netfile_agency).to eq(agency)
      expect(filing.filed_at.to_date).to eq(today)
      # The form number is read back out of the title the feed supplies.
      expect(filing.form_name).to eq('460')
    end

    it 'excludes filings filed outside the requested range' do
      stub_netfile

      filings = client.filings_by_date(today, today, agency)

      expect(filings.map { |filing| filing['id'] }).to eq(%w[217685109])
    end

    it 'skips a filing whose metadata cannot be parsed rather than failing the run' do
      stub_netfile(infos: {
        '217685109' => fixture('filing_info_217685109.json'),
        '217680684' => '<html>gateway timeout</html>',
        '217680490' => fixture('filing_info_217680490.json'),
      })

      filings = client.filings_by_date(today - 7, today, agency)

      expect(filings.map { |filing| filing['id'] }).to eq(%w[217685109 217680490])
    end

    it 'skips a filing whose filing date cannot be parsed' do
      undated = JSON.parse(fixture('filing_info_217680684.json')).merge('filingDate' => 'not a date')
      stub_netfile(infos: {
        '217685109' => fixture('filing_info_217685109.json'),
        '217680684' => undated.to_json,
        '217680490' => fixture('filing_info_217680490.json'),
      })

      filings = client.filings_by_date(today - 7, today, agency)

      expect(filings.map { |filing| filing['id'] }).to eq(%w[217685109 217680490])
    end

    it 'skips a filing whose filing date is null' do
      undated = JSON.parse(fixture('filing_info_217680684.json')).merge('filingDate' => nil)
      stub_netfile(infos: {
        '217685109' => fixture('filing_info_217685109.json'),
        '217680684' => undated.to_json,
        '217680490' => fixture('filing_info_217680490.json'),
      })

      filings = client.filings_by_date(today - 7, today, agency)

      expect(filings.map { |filing| filing['id'] }).to eq(%w[217685109 217680490])
    end

    it 'skips a filing that belongs to a different agency' do
      other_agency = JSON.parse(fixture('filing_info_217680684.json')).merge('agency' => 'SFO')
      stub_netfile(infos: {
        '217685109' => fixture('filing_info_217685109.json'),
        '217680684' => other_agency.to_json,
        '217680490' => fixture('filing_info_217680490.json'),
      })

      filings = client.filings_by_date(today - 7, today, agency)

      expect(filings.map { |filing| filing['id'] }).to eq(%w[217685109 217680490])
    end

    it 'raises when the feed lists filings but none of their metadata can be read' do
      stub_netfile(infos: {
        '217685109' => 'bad gateway',
        '217680684' => 'bad gateway',
        '217680490' => 'bad gateway',
      })

      expect { client.filings_by_date(today - 7, today, agency) }
        .to raise_error(described_class::FeedUnavailable, /listed 3 filings/)
    end

    it 'returns nothing when the feed has no items' do
      stub_netfile(feed: '<rss version="2.0"><channel></channel></rss>')

      expect(client.filings_by_date(today - 7, today, agency)).to eq([])
    end

    it 'raises rather than reporting an empty day when the feed is gone' do
      allow(client).to receive(:get)
        .and_raise(described_class::FeedUnavailable, 'Netfile request failed: 404 Not Found')

      expect { client.filings_by_date(today - 7, today, agency) }
        .to raise_error(described_class::FeedUnavailable)
    end

    it 'refuses a range older than the feed can serve' do
      stub_netfile

      expect { client.filings_by_date(today - 30, today, agency) }
        .to raise_error(described_class::FeedWindowExceeded, /only covers 15 days/)
    end

    it 'accepts a range reaching exactly to the edge of the feed window' do
      stub_netfile

      expect { client.filings_by_date(today - described_class::FEED_HISTORY_DAYS, today, agency) }
        .not_to raise_error
    end
  end

  # The tests above replace #get, so these drive Net::HTTP directly to cover the
  # request building and the non-success handling that produced the original
  # "401 Unauthorized" report.
  describe 'the HTTP boundary' do
    # Every request is recorded, because one call fans out into the feed request
    # followed by a metadata request per filing.
    # body may be a string, or a callable resolving the body per URL.
    def stub_http(code:, message: '', body: '')
      @requested = []
      http = double('http')
      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(http).to receive(:request) do |request|
        url = request.uri.to_s
        @requested << url
        resolved = body.respond_to?(:call) ? body.call(url) : body
        double('response', code: code, message: message, body: resolved)
      end
    end

    # Serves the feed, then the matching metadata fixture per filing.
    let(:feed_then_metadata) do
      lambda do |url|
        if url.include?('/list/filing/rss/')
          fixture('coak_filing_log.xml')
        else
          fixture("filing_info_#{url[%r{/filing/info/(\d+)}, 1]}.json")
        end
      end
    end

    it 'requests the agency feed from the Connect2 filing log first' do
      stub_http(code: '200', body: feed_then_metadata)

      client.filings_by_date(today, today, agency)

      expect(@requested.first)
        .to eq('https://netfile.com/Connect2/api/public/list/filing/rss/COAK?Application=Campaign')
    end

    it 'then requests metadata for each filing in the feed' do
      stub_http(code: '200', body: feed_then_metadata)

      client.filings_by_date(today, today, agency)

      expect(@requested.drop(1)).to eq([
        'https://netfile.com/Connect2/api/public/filing/info/217685109',
        'https://netfile.com/Connect2/api/public/filing/info/217680684',
        'https://netfile.com/Connect2/api/public/filing/info/217680490',
      ])
    end

    it 'turns a non-success feed response into FeedUnavailable' do
      stub_http(code: '401', message: 'Unauthorized')

      expect { client.filings_by_date(today, today, agency) }
        .to raise_error(described_class::FeedUnavailable, /401 Unauthorized/)
    end

    it 'turns a non-success PDF response into FeedUnavailable' do
      stub_http(code: '500', message: 'Internal Server Error')

      expect { client.fetch_pdf('217685109') }
        .to raise_error(described_class::FeedUnavailable, /500 Internal Server Error/)
    end

    it 'returns the PDF body on success' do
      stub_http(code: '200', body: '%PDF-1.4 fake')

      expect(client.fetch_pdf('217685109')).to eq('%PDF-1.4 fake')
      expect(@requested).to eq(['https://netfile.com/Connect2/api/public/image/217685109'])
    end
  end
end
