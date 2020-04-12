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
        with_pagination do |current_page|
          request = Net::HTTP::Post.new(BASE_URL + 'public/campaign/export/cal201/summary/filing')
          request['Accept'] = 'application/json'
          request.body = URI.encode_www_form(
            FilingId: filing_id,
            PageSize: 200,
          )

          response = http.request(request)
          raise "Request Failed: " + request.inspect unless response.code.to_i < 300

          JSON.parse(response.body).values_at('results', 'totalMatchingPages')
        end
      end
    end

    def fetch_transaction_contents(filing_id)
      Net::HTTP.start(BASE_URL.host, BASE_URL.port, use_ssl: true) do |http|
        with_pagination do |current_page|
          request = Net::HTTP::Post.new(BASE_URL + 'public/campaign/export/cal201/transaction/filing')
          request['Accept'] = 'application/json'
          request.body = URI.encode_www_form(
            FilingId: filing_id,
            CurrentPageIndex: current_page,
            PageSize: 200,
          )

          response = http.request(request)
          raise "Request Failed: " + request.inspect unless response.code.to_i < 300

          JSON.parse(response.body).values_at('results', 'totalMatchingPages')
        end
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

    def get_filing(filing_id)
      Net::HTTP.start(BASE_URL.host, BASE_URL.port, use_ssl: true) do |http|
        request = Net::HTTP::Get.new(BASE_URL + "public/filing/info/#{filing_id}")
        request['Accept'] = 'application/json'

        response = http.request(request)
        raise 'Error: ' + response.inspect unless response.code.to_i < 300

        return JSON.parse(response.body)
      end
    end

    def each_filing(form: nil, &block)
      return to_enum(:each_filing) unless block_given?

      Net::HTTP.start(BASE_URL.host, BASE_URL.port, use_ssl: true) do |http|
        with_pagination do |current_page|
          request = Net::HTTP::Post.new(BASE_URL + 'public/list/filing')
          request['Accept'] = 'application/json'
          request.body = URI.encode_www_form(
            AID: 'COAK',
            CurrentPageIndex: current_page,
            Form: form,
          )

          response = http.request(request)
          raise 'Error: ' + response.inspect unless response.code.to_i < 300

          filings, num_pages =
            JSON.parse(response.body).values_at('filings', 'totalMatchingPages')

          filings.each(&block)

          [nil, num_pages]
        end
      end
    end

    private

    def with_pagination
      current_page = 0
      results = []

      loop do
        page_results, num_pages = yield current_page
        results.concat(page_results)
        break if num_pages == current_page
        current_page += 1
      end

      results
    end
  end
end
