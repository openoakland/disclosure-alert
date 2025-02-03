# frozen_string_literal: true

class DisclosureDownloader
  def initialize(agency = NetfileAgency.coak)
    @netfile = Netfile::Client.new
    @agency = agency
  end

  def download
    latest = Filing.where(netfile_agency: @agency).order(filed_at: :desc).first
    puts '==================================================================='
    puts "Beginning State for Netfile agency #{@agency.shortcut}:"
    puts
    puts "Filings: #{Filing.where(netfile_agency: @agency).count}"
    puts "Latest: #{latest&.filed_at}"
    puts '==================================================================='

    @netfile.each_filing(agency: @agency) do |json|
      filing = Filing.from_json(json)

      if filing.new_record?
        puts "Syncing new filing: #{filing.inspect}"
      end

      break if latest && latest == filing
      break if Date.today - filing.filed_at.to_date > 14

      download_filing(filing)
      download_unamended_version(filing)
    end

    latest = Filing.where(netfile_agency: @agency).order(filed_at: :desc).first
    puts '==================================================================='
    puts 'Ending State:'
    puts
    puts "Filings: #{Filing.where(netfile_agency: @agency).count}"
    puts "Latest: #{latest&.filed_at}"
    puts '==================================================================='
  end

  # Downloads filings (and contents if necessary) from oldest to newest. Good to
  # use if downloading is broken for an extended period.
  def backfill_filings(since)
    puts '==================================================================='
    puts "Fetching filings since #{since}..."
    puts ''
    filings_in_range = @netfile.each_filing(agency: @agency)
      .lazy
      .map { |json| Filing.from_json(json) }
      .take_while { |filing| filing.filed_at >= since }
      .to_a
    filings, already_downloaded_filings = filings_in_range.partition(&:new_record?)
    puts "Filings to fetch: #{filings.length}"
    puts "                  (#{already_downloaded_filings.length} already downloaded)"
    puts '==================================================================='

    filings.reverse.each_with_index do |filing, i|
      puts "Downloading #{i.to_s.rjust(3)}/#{filings.length}: #{filing.filer_name.truncate(30).ljust(30)} - #{filing.form_name} (Filed: #{filing.filed_at})"
      download_filing(filing)
      download_unamended_version(filing)
    end
  end

  # Goes through old Filings and downloads the contents if missing.
  def backfill_contents
    puts '==================================================================='
    puts 'Backfilling Filing Contents:'
    puts
    puts "Filings: #{Filing.count}"
    puts '==================================================================='

    num_backfilled_by_name = Hash.new(0)
    Filing.find_each do |filing|
      next unless ['410'].include?(filing.form_name)
      next if filing.contents.present?

      download_filing(filing)
      num_backfilled_by_name[filing.form_name] += 1
    end

    puts '==================================================================='
    puts 'Backfill Completed:'
    puts
    puts "Backfilled: #{num_backfilled_by_name.map { |k, v| "Form #{k}: #{v}" }.join(', ')}"
    puts '==================================================================='
  end

  private

  def download_filing(filing)
    contents =
      case filing.form_name
      when '410'
        raw = @netfile.fetch_calfile(filing.id)
        raw.present? ? raw.lines : nil
      when '460', '496', '497'
        raw = @netfile.fetch_calfile(filing.id)
        raw.present? ? CalFileParser.new(raw).parse : nil
      end

    contents_xml =
      case filing.form_name
      when '700'
        @netfile
          .fetch_calfile(filing.id)
      end

    filing.update(contents: contents, contents_xml: contents_xml)
  rescue StandardError => ex
    user_input = retry?(ex)
    retry if user_input == :retry

    unless user_input == :skip
      raise FilingDownloadError, "Error downloading filing #{filing.id}: #{ex.message}"
    end
  end

  def download_unamended_version(filing)
    return unless filing.amended_filing_id && !Filing.exists?(filing.amended_filing_id)

    # If the filing was amended, but we haven't downloaded the original
    # un-amended filing yet, let's grab it now.
    amended_json = @netfile.get_filing(filing.amended_filing_id)
    # Netfile bug: Some fields have different names in the GET
    # /public/filing/info/{FilingId} endpoint than in the filing list
    # endpoint.
    amended_json['id'] = amended_json['filingId']
    amended_json['filerStateId'] = amended_json['sosFilerId']
    amended_json['amendedFilingId'] = amended_json['amends']
    # And some fields are missing.
    amended_json['agency'] = filing.netfile_agency.netfile_id
    amended_json['title'] = filing.title
    amended_json['form'] = filing.form
    amended_filing = Filing.from_json(amended_json)
    puts "Syncing un-amended filing: #{amended_filing}"
    download_filing(amended_filing)
  end

  def retry?(exception)
    return unless $stdout.tty?

    puts "Error: #{exception} (#{exception.message})"
    $stdout.write "Retry? (y = yes; n = no, s = skip): "
    {
      'y' => :retry,
      'n' => nil,
      's' => :skip
    }[gets.chomp.downcase]
  end

  class FilingDownloadError < StandardError; end
end
