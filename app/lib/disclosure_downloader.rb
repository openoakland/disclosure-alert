# frozen_string_literal: true

require_dependency 'netfile/form_460_pdf_parser'
require_dependency 'netfile/form_497_pdf_parser'

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
        download_filing(filing)
      end
    end

    @logger.puts '==================================================================='
    @logger.puts 'Ending State:'
    @logger.puts
    @logger.puts "Filings: #{Filing.where(netfile_agency: @agency).count}"
    @logger.puts "Latest: #{Filing.where(netfile_agency: @agency).maximum(:filed_at)}"
    @logger.puts '==================================================================='
  end

  def download_range(start_date, end_date)
    puts "Fetching filings from #{start_date} to #{end_date}..."

    @netfile.filings_by_date(start_date, end_date).each do |json|
      filing = Filing.from_json(json)

      if filing.new_record?
        puts "Syncing new filing: #{filing.inspect}"
        filing.save!
      end

      download_filing(filing) if filing.contents.nil?
    end

    puts "Done. Total filings: #{Filing.count}"
  end

  def backfill_contents
    filings = Filing.where(contents: nil)
    puts "Backfilling contents for #{filings.count} filings..."

    filings.each do |filing|
      download_filing(filing)
    end

    puts 'Done.'
  end

  private

  def download_filing(filing)
    case filing.form_name
    when '460'
      download_460(filing)
    when '497'
      download_497(filing)
    end
  rescue StandardError => ex
    puts "  Error downloading filing #{filing.id}: #{ex.message}. Skipping."
  end

  def download_460(filing)
    puts "  Downloading PDF for filing #{filing.id} (460)..."
    pdf_bytes = @netfile.fetch_pdf(filing.id)
    contents = Netfile::Form460PdfParser.new(pdf_bytes).parse
    filing.update!(contents: contents)
    puts "  Parsed summary: contributions=#{contents.find { |r| r['line_Item'] == '5' }&.dig('amount_A')} expenditures=#{contents.find { |r| r['line_Item'] == '11' }&.dig('amount_A')}"
  end

  def download_497(filing)
    puts "  Downloading PDF for filing #{filing.id} (497)..."
    pdf_bytes = @netfile.fetch_pdf(filing.id)
    sections = Netfile::Form497PdfParser.new(pdf_bytes).parse

    if sections.empty?
      puts "  Warning: no transactions parsed from Form 497 PDF for filing #{filing.id}."
      return
    end

    # A 497 filing almost always has only one section. If both exist, create
    # a second filing record for the other section — but for now just handle
    # the primary (first) section.
    primary = sections.first
    form_code = primary[:type] == 'LCR' ? '39' : '38'
    filing.update!(form: form_code, contents: primary[:contents])
    puts "  Parsed 497 #{primary[:type]} with #{primary[:contents].length} transaction(s)."

    if sections.length > 1
      puts "  Note: filing #{filing.id} has both LCR and LCM sections; only LCR stored."
    end
  end
end
