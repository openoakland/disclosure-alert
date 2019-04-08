# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'zip'

module Netfile
  # Client to get responses from Netfile
  class Client
    BASE_URL = URI('https://netfile.com/Connect2/api/')

    def initialize; end

    def fetch_summary_contents(filing_id)
      Net::HTTP.start(BASE_URL.host, BASE_URL.port, use_ssl: true) do |http|
        request = Net::HTTP::Post.new(BASE_URL + 'public/campaign/export/cal201/summary/filing')
        request['Accept'] = 'application/json'
        request.body = URI.encode_www_form(
          FilingId: filing_id,
          PageSize: 200,
        )

        response = http.request(request)
        raise "Request Failed: " + request.inspect unless response.code.to_i < 300

        results, num_pages = JSON.parse(response.body).values_at('results', 'totalMatchingPages')
        raise "Error: More than one page would be returned. Bump PageSize." if num_pages > 1

        results
      end
    end

    def fetch_transaction_contents(filing_id)
      Net::HTTP.start(BASE_URL.host, BASE_URL.port, use_ssl: true) do |http|
        request = Net::HTTP::Post.new(BASE_URL + 'public/campaign/export/cal201/transaction/filing')
        request['Accept'] = 'application/json'
        request.body = URI.encode_www_form(
          FilingId: filing_id,
          PageSize: 200,
        )

        response = http.request(request)
        raise "Request Failed: " + request.inspect unless response.code.to_i < 300

        results, num_pages = JSON.parse(response.body).values_at('results', 'totalMatchingPages')
        raise "Error: More than one page would be returned. Bump PageSize." if num_pages > 1

        results
      end
    end

    def fetch_calfile_xml(filing_id)
      Net::HTTP.start(BASE_URL.host, BASE_URL.port, use_ssl: true) do |http|
        request = Net::HTTP::Get.new(BASE_URL + "public/efile/#{filing_id}")
        request['Accept'] = 'application/zip'

        response = http.request(request)

        if response.message == 'EfileNotFoundException'
          # perhaps the filing was removed?
          return nil
        end

        raise "Request Failed: " + response.inspect unless response.code.to_i < 300

        Zip::InputStream.open(StringIO.new(response.body)) do |zip|
          zip.get_next_entry
          zip.read
        end
      end
    end

    def each_filing(form: nil, &block)
      return to_enum(:each_filing) unless block_given?

      current_page = 0

      Net::HTTP.start(BASE_URL.host, BASE_URL.port, use_ssl: true) do |http|
        loop do
          request = Net::HTTP::Post.new(BASE_URL + 'public/list/filing')
          request['Accept'] = 'application/json'
          request.body = URI.encode_www_form(
            AID: 'COAK',
            CurrentPageIndex: current_page,
            Form: form,
          )

          response = http.request(request)
          raise 'Error: ' + response.inspect unless response.code.to_i < 300

          filings, total_count =
            JSON.parse(response.body).values_at('filings', 'totalMatchingCount')

          remaining_count ||= total_count
          remaining_count -= filings.length

          filings.each(&block)

          break if remaining_count <= 0

          current_page += 1
        end
      end
    end
  end
end
