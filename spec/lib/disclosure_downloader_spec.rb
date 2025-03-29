require 'rails_helper'

RSpec.describe DisclosureDownloader do
  class FakeNetfileClient
    def initialize(fake_filings)
      @filings = Array(fake_filings)
    end

    def each_filing(agency:, &block)
      @filings.each { |filing| block.call(filing.metadata) }
    end

    def fetch_calfile(id)
      @filings
        .find { |filing| filing.metadata['id'].to_i == id.to_i }
        .data
    end
  end

  FakeFiling = Struct.new(:metadata, :data)

  describe '#download' do
    let(:downloader) { described_class.new(NetfileAgency.coak, log) }
    let(:filed_at) { Time.now - 24.hours }
    let(:fake_client) { FakeNetfileClient.new([fake_filing]) }
    let(:fake_filing) { FakeFiling.new(fake_filing_metadata, fake_filing_data) }
    let(:fake_filing_metadata) do
      {
        id: "12345",
        filerStateId: "1111",
        filerName: 'Foo bar for Mayor',
        title: "title",
        filingDate: filed_at.to_s,
        amendmentSequenceNumber: 0,
        amendedFilingId: nil,
        form: 36, # FPPC Form 496
        agency: NetfileAgency.coak.netfile_id,
      }.stringify_keys
    end
    let(:fake_filing_data) do
      File.read(Rails.root.join('spec', 'fixtures', 'cal', 'F496-174292914.txt'))
    end
    let(:log) { StringIO.new }

    before do
      allow(Netfile::Client).to receive(:new).and_return(fake_client)
    end

    after do |ex|
      if ex.exception
        puts "Downloader logged to stdout:"
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

    context 'when the downloading gives a 500 error' do
      before do
        allow(fake_client).to receive(:fetch_calfile)
          .with(fake_filing_metadata['id'].to_i)
          .and_raise(Netfile::Client::InternalServerError)
      end

      it 'saves the error' do
        expect { downloader.download }
          .to change(Filing, :count)
          .by(1)

        last_filing = Filing.last
        expect(last_filing.contents).to match("error" => "Netfile::Client::InternalServerError", "message" => be_a(String))
      end
    end

    context 'when the downloading gives a 404 error' do
      before do
        allow(fake_client).to receive(:fetch_calfile)
          .with(fake_filing_metadata['id'].to_i)
          .and_raise(Netfile::Client::NotFoundError)
      end

      it 'saves the error' do
        expect { downloader.download }
          .to change(Filing, :count)
          .by(1)

        last_filing = Filing.last
        expect(last_filing.contents).to match("error" => "Netfile::Client::NotFoundError", "message" => be_a(String))
      end
    end
  end
end
