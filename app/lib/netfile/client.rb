# frozen_string_literal: true

require 'date'
require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'

module Netfile
  # Client to get responses from Netfile.
  #
  # Filing discovery runs off NetFile's Connect2 public endpoints. The newer
  # "public portal" API (netfile.com/api/public/sites) is not usable from a
  # script: it sits behind a Cloudflare Turnstile challenge and answers
  # 401 "A valid session is required" unless the caller presents a
  # cf-turnstile-response token minted by a browser. That header takes a
  # Turnstile token rather than a credential, so no API key substitutes for it.
  #
  # Connect2 is the older generation of the API and may be withdrawn. Every
  # request here raises FeedUnavailable on a non-success response so that a
  # withdrawal surfaces as an error instead of looking like a quiet day with no
  # filings.
  class Client
    CONNECT2_URL = 'https://netfile.com/Connect2/api/public'

    # The filing log feed advertises "a maximum history of 15 days or 1000
    # items", so it cannot answer questions about older filings.
    FEED_HISTORY_DAYS = 15

    Error = Class.new(StandardError)
    FeedUnavailable = Class.new(Error)
    FeedWindowExceeded = Class.new(Error)

    def initialize; end

    # Downloads the original PDF for a filing.
    def fetch_pdf(filing_id)
      get("#{CONNECT2_URL}/image/#{filing_id}", accept: 'application/pdf')
    end

    # Filings for +agency+ filed between start_date and end_date (inclusive),
    # as hashes in the shape Filing.from_json expects.
    #
    # The feed carries no per-item filing date, so the date of each filing in
    # the window is read from its own metadata. That is one extra request per
    # filing in the feed, which is acceptable for a nightly run over a single
    # agency but makes this a poor fit for large backfills.
    def filings_by_date(start_date, end_date, agency)
      range = start_date.to_date..end_date.to_date
      oldest_available = Date.today - FEED_HISTORY_DAYS

      if range.begin < oldest_available
        raise FeedWindowExceeded,
              "The Connect2 filing log only covers #{FEED_HISTORY_DAYS} days " \
              "(back to #{oldest_available}), so it cannot serve filings " \
              "filed on #{range.begin}."
      end

      entries = feed_entries(agency)
      unreadable = 0

      filings = entries.filter_map do |entry|
        filing = filing_metadata(entry, agency)

        if filing.nil?
          unreadable += 1
          next
        end

        next unless range.cover?(DateTime.parse(filing['filingDate']).to_date)

        filing
      end

      # The feed listing filings while not one of them can be read means the
      # metadata endpoint is broken, which must not read as a quiet day.
      if entries.any? && unreadable == entries.length
        raise FeedUnavailable,
              "The #{agency.shortcut} feed listed #{entries.length} filings but " \
              'metadata could not be read for any of them.'
      end

      filings
    end

    private

    # Filing ids and form names from the agency's real-time filing log. The
    # feed is ordered newest first and spans FEED_HISTORY_DAYS.
    def feed_entries(agency)
      body = get(
        "#{CONNECT2_URL}/list/filing/rss/#{agency.shortcut}?Application=Campaign",
        accept: 'application/rss+xml',
      )

      Nokogiri::XML(body).xpath('//item').filter_map do |item|
        id = item.at_xpath('link')&.text.to_s[%r{/image/(\d+)}, 1]
        next if id.nil?

        # e.g. "FPPC Form 460 (9/20/2026 - 10/17/2026)". Forms.from_filings
        # reads the form number back out of this, so it is passed through whole.
        { 'id' => id, 'formName' => item.at_xpath('description')&.text }
      end
    end

    # Metadata for one filing, mapped onto the keys Filing.from_json reads.
    # Returns nil for a filing that cannot be fetched or that belongs to
    # another agency, so that one bad filing does not fail the whole run.
    def filing_metadata(entry, agency)
      info = JSON.parse(get("#{CONNECT2_URL}/filing/info/#{entry.fetch('id')}"))

      unless info['agency'].to_s.casecmp?(agency.shortcut)
        warn "Skipping filing #{entry['id']}: belongs to #{info['agency'].inspect}, not #{agency.shortcut}."
        return nil
      end

      filing = {
        'id' => info.fetch('filingId'),
        'filerName' => info['filerName'],
        'formName' => entry['formName'],
        'agency' => agency.netfile_id,
        'filingDate' => info.fetch('filingDate'),
        'sequenceNumber' => info['amendmentSequenceNumber'],
      }

      # Parsed here only to reject an unusable date, so that a bad one is
      # skipped along with every other unreadable filing instead of raising
      # out of the range check in filings_by_date. A null date arrives as nil,
      # which DateTime.parse answers with TypeError rather than Date::Error.
      DateTime.parse(filing['filingDate'])

      filing
    rescue Error, JSON::ParserError, KeyError, Date::Error, TypeError => ex
      # JSON::ParserError quotes the whole response body, which is an entire
      # error page when Connect2 is unwell, so the reason is truncated.
      reason = ex.message.tr("\n", ' ').slice(0, 200)
      warn "Skipping filing #{entry['id']}: #{ex.class}: #{reason}"
      nil
    end

    def get(url, accept: 'application/json')
      uri = URI(url)

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Get.new(uri)
        request['Accept'] = accept
        http.request(request)
      end

      unless response.code.to_i < 300
        raise FeedUnavailable,
              "Netfile request failed: #{response.code} #{response.message} (#{uri})"
      end

      response.body
    end
  end
end
