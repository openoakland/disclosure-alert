# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module Netfile
  # Client to get responses from Netfile
  class Client
    PUBLIC_API_URL = 'https://netfile.com/api/public/sites/api'

    def initialize; end

    # TODO: Content fetching (fetch_summary_contents, fetch_transaction_contents,
    # fetch_calfile_xml, get_filing) was removed when the Connect2 API was shut down.
    # The structured data (Form 460 totals, 497 transaction details, 700 XML) is no
    # longer available without authenticated v2 API credentials. See git history and
    # DisclosureDownloader#download_filing for the original implementation.

    # Fetches filings filed between start_date and end_date (inclusive).
    # No credentials required.
    def filings_by_date(start_date, end_date)
      results = []
      page = 1

      loop do
        uri = URI("#{PUBLIC_API_URL}/filings/byDate")
        uri.query = URI.encode_www_form(
          agencyCode: 'COAK',
          startDate: start_date.to_s,
          endDate: end_date.to_s,
          page: page,
          pageSize: 100,
        )

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          request = Net::HTTP::Get.new(uri)
          request['Accept'] = 'application/json'
          http.request(request)
        end

        raise "Request failed: #{response.code} #{response.message}" unless response.code.to_i < 300

        body = JSON.parse(response.body)
        filings = body['filings'] || []
        results.concat(filings)

        break if filings.empty? || results.length >= body['totalCount'].to_i
        page += 1
      end

      results
    end
  end
end
