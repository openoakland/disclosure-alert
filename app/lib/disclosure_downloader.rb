# frozen_string_literal: true

class DisclosureDownloader
  def initialize(agency = NetfileAgency.coak, logger = $stdout)
    @netfile = Netfile::Client.new
    @agency = agency
    @logger = logger
  end

  def download
    # Overlap by 1 day to catch filings that arrived after the last run
    # on their filing date. find_or_initialize_by ensures no duplicates.
    start_date = (Filing.where(netfile_agency: @agency).maximum(:filed_at)&.to_date || Date.today - 14) - 1
    end_date = Date.today

    @logger.puts '==================================================================='
    @logger.puts "Beginning State for Netfile agency #{@agency.shortcut}:"
    @logger.puts
    @logger.puts "Filings: #{Filing.where(netfile_agency: @agency).count}"
    @logger.puts "Fetching: #{start_date} to #{end_date}"
    @logger.puts '==================================================================='

    @netfile.filings_by_date(start_date, end_date).each do |json|
      filing = Filing.from_json(json)

      if filing.new_record?
        @logger.puts "Syncing new filing: #{filing.inspect}"
        filing.save!
      end
    end

    # TODO: download_filing and backfill_contents were removed when the Connect2
    # content APIs were shut down. They fetched structured JSON for Forms 460, 496,
    # 497, and 700, which was stored in Filing#contents / Filing#contents_xml and
    # rendered inline in alert emails. Restoring this requires authenticated v2 API
    # credentials (NETFILE_API_KEY / NETFILE_API_SECRET) and a new client
    # implementation against /api/campaign/cal/v101/transaction-elements.
    # See git history for the original download_filing and backfill_contents methods.

    @logger.puts '==================================================================='
    @logger.puts 'Ending State:'
    @logger.puts
    @logger.puts "Filings: #{Filing.where(netfile_agency: @agency).count}"
    @logger.puts "Latest: #{Filing.where(netfile_agency: @agency).maximum(:filed_at)}"
    @logger.puts '==================================================================='
  end
end
