require 'rails_helper'

RSpec.describe DisclosureDownloader do
  class FakeNetfileClient
    def initialize(fake_filings)
      @filings = Array(fake_filings)
    end

    def filings_by_date(start_date, end_date)
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
  end
end
