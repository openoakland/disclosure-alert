require 'rails_helper'

RSpec.describe DisclosureDownloader do
  class FakeNetfileClient
    attr_reader :requested_range

    def initialize(fake_filings)
      @filings = Array(fake_filings)
    end

    def filings_by_date(start_date, end_date, agency = nil)
      @requested_range = [start_date, end_date]
      @filings.map(&:metadata)
    end

    def fetch_pdf(id)
      @filings
        .find { |filing| filing.metadata['id'].to_i == id.to_i }
        &.data
    end
  end

  FakeFiling = Struct.new(:metadata, :data)

  describe '#download' do
    let(:downloader) { described_class.new(NetfileAgency.coak, log) }
    let(:filed_at) { Time.now - 24.hours }
    let(:fake_client) { FakeNetfileClient.new([fake_filing]) }
    let(:fake_filing) { FakeFiling.new(fake_filing_metadata, nil) }
    let(:fake_filing_metadata) do
      {
        'id' => '12345',
        'filerName' => 'Foo bar for Mayor',
        'formName' => 'FPPC Form 496',
        'filingDate' => filed_at.to_s,
        'sequenceNumber' => 0,
        'agency' => NetfileAgency.coak.netfile_id,
      }
    end
    let(:log) { StringIO.new }

    before do
      allow(Netfile::Client).to receive(:new).and_return(fake_client)
    end

    after do |ex|
      if ex.exception
        puts "Downloader logged:"
        puts log.tap(&:rewind).read
      end
    end

    it 'downloads a 496 filing' do
      expect { downloader.download }
        .to change(Filing, :count)
        .by(1)

      last_filing = Filing.last
      expect(last_filing.filer_name).to eq(fake_filing_metadata['filerName'])
      expect(last_filing.netfile_agency).to eq(NetfileAgency.coak)
    end

    context 'when the agency has no filings newer than the feed window' do
      # An agency left behind, as SFO was: its newest filing predates the feed's
      # history, so an unclamped start date raises FeedWindowExceeded every
      # night and can never recover, because nothing lands to move it forward.
      let!(:stale_filing) do
        Filing.create!(
          id: 999_001,
          filer_name: 'Long Ago Committee',
          title: 'FPPC Form 460',
          form: '0',
          netfile_agency: NetfileAgency.coak,
          filed_at: Date.today - 120,
          amendment_sequence_number: 0,
        )
      end

      it 'asks only for the window the feed can serve' do
        downloader.download

        start_date, end_date = fake_client.requested_range
        expect(start_date).to eq(Date.today - Netfile::Client::FEED_HISTORY_DAYS)
        expect(end_date).to eq(Date.today)
      end

      it 'reports the gap it cannot fetch' do
        downloader.download

        expect(log.tap(&:rewind).read)
          .to match(/Gap: newest COAK filing is #{Date.today - 120}.*only reaches/)
      end
    end

    context 'when the agency is up to date' do
      let!(:recent_filing) do
        Filing.create!(
          id: 999_002,
          filer_name: 'Recent Committee',
          title: 'FPPC Form 460',
          form: '0',
          netfile_agency: NetfileAgency.coak,
          filed_at: Date.today - 2,
          amendment_sequence_number: 0,
        )
      end

      it 'keeps the one-day overlap and does not clamp' do
        downloader.download

        start_date, = fake_client.requested_range
        expect(start_date).to eq(Date.today - 3)
      end
    end
  end
end
