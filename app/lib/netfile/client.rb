# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module Netfile
  # Client to get responses from Netfile
  class Client
    PUBLIC_API_URL = 'https://netfile.com/api/public/sites/api'

    def initialize; end

    CONNECT2_IMAGE_URL = 'https://netfile.com/Connect2/api/public/image'

    # Downloads the original PDF for a filing. The Connect2 image endpoint
    # remains live even though the structured-data endpoints are gone.
    def fetch_pdf(filing_id)
      uri = URI("#{CONNECT2_IMAGE_URL}/#{filing_id}")
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.get(uri.request_uri)
      end
      raise "PDF fetch failed: #{response.code} #{response.message}" unless response.code.to_i < 300
      response.body
    end

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
