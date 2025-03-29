# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'zip'

module Netfile
  # Client to get responses from Netfile
  class Client
    BASE_URL = URI('https://netfile.com/Connect2/api/')

    DownloadError = Class.new(StandardError)

    InternalServerError = Class.new(DownloadError)
    NotFoundError = Class.new(DownloadError)

    def initialize; end

    def fetch_summary_contents(filing_id)
      []
      # TODO: Replace this with a working implementation based on the new
      # "Query" endpoint (Documented here: https://www.netfile.com/Connect2/api/ui/Query)
      # once that endpoint allows for querying an arbitrary Filing ID.
      #
      # Net::HTTP.start(BASE_URL.host, BASE_URL.port, use_ssl: true) do |http|
      #   with_pagination do |current_page|
      #     request = Net::HTTP::Post.new(BASE_URL + 'public/campaign/export/cal201/summary/filing')
      #     request['Accept'] = 'application/json'
      #     request.body = URI.encode_www_form(
      #       FilingId: filing_id,
      #       PageSize: 200,
      #     )

      #     response = http.request(request)
      #     raise "Request Failed: " + request.inspect unless response.code.to_i < 300

      #     JSON.parse(response.body).values_at('results', 'totalMatchingPages')
      #   end
      # end
    end

    def fetch_transaction_contents(filing_id)
      []
      # TODO: Replace this with a working implementation based on the new
      # "Query" endpoint (Documented here: https://www.netfile.com/Connect2/api/ui/Query)
      # once that endpoint allows for querying an arbitrary Filing ID.
      #
      # Net::HTTP.start(BASE_URL.host, BASE_URL.port, use_ssl: true) do |http|
      #   with_pagination do |current_page|
      #     request = Net::HTTP::Post.new(BASE_URL + 'public/campaign/export/cal201/transaction/filing')
      #     request['Accept'] = 'application/json'
      #     request.body = URI.encode_www_form(
      #       FilingId: filing_id,
      #       CurrentPageIndex: current_page,
      #       PageSize: 200,
      #     )

      #     response = http.request(request)
      #     raise "Request Failed: " + request.inspect unless response.code.to_i < 300

      #     JSON.parse(response.body).values_at('results', 'totalMatchingPages')
      #   end
      # end
    end

    def fetch_calfile(filing_id)
      Net::HTTP.start(BASE_URL.host, BASE_URL.port, use_ssl: true) do |http|
        request = Net::HTTP::Get.new(BASE_URL + "public/efile/#{filing_id}")
        request['Accept'] = 'application/zip'

        response = http.request(request)

        if response.message == 'EfileNotFoundException'
          # perhaps the filing was removed?
          return nil
        end

        raise_error(response) unless response.code.to_i < 300

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
        raise_error(response) unless response.code.to_i < 300

        return JSON.parse(response.body)
      end
    end

    def each_filing(form: nil, agency:, &block)
      return to_enum(:each_filing, form: form, agency: agency) unless block_given?

      Net::HTTP.start(BASE_URL.host, BASE_URL.port, use_ssl: true) do |http|
        with_pagination do |current_page|
          request = Net::HTTP::Post.new(BASE_URL + 'public/list/filing')
          request['Accept'] = 'application/json'
          request.body = URI.encode_www_form(
            AID: agency.shortcut,
            CurrentPageIndex: current_page,
            Form: form,
          )

          response = http.request(request)
          raise_error(response) unless response.code.to_i < 300

          filings, num_pages =
            JSON.parse(response.body).values_at('filings', 'totalMatchingPages')

          filings.each(&block)

          [[], num_pages]
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

    def raise_error(response)
      if response.is_a?(Net::HTTPInternalServerError)
        raise InternalServerError.new("NetFile Error: #{response.body}")
      elsif response.is_a?(Net::HTTPNotFound)
        raise NotFoundError.new("NetFile Error: #{response.body}")
      else
        raise "Error: #{response.body}"
      end
    end
  end
end
