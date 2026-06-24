# frozen_string_literal: true

require 'pdf-reader'

module Netfile
  # Extracts Form 497 (Late Contribution Report) transaction data from the PDF
  # and determines whether the filing is LCR (contributions received) or LCM
  # (contributions made).
  #
  # The FPPC Form 497 has two sections:
  #   Part 1 — Contributions Received  → LCR (form code 39)
  #   Part 2 — Contributions Made      → LCM (form code 38)
  #
  # Returns an array of {type:, contents:} hashes — one per section that has
  # actual transaction rows.  contents is an array of row hashes compatible
  # with the _form_497_lcr / _form_497_lcm partials.
  class Form497PdfParser
    PART1_HEADER = /1\.\s+Contribution\(s\)\s+Received/i
    PART2_HEADER = /2\.\s+Contribution\(s\)\s+Made/i

    # Transaction rows begin with a date flush-left in their column, have the
    # contributor name in the middle, and the dollar amount at the far right
    # separated by a wide whitespace gap.
    TRANSACTION_LINE = /^\s+(\d{2}\/\d{2}\/\d{4})\s+(.+?)\s{5,}([\d,]+\.\d{2})\s*$/

    # Lines that look like address / ID boilerplate after a name
    ADDRESS_LINE = /\b[A-Z]{2}\s+\d{5}\b|Committee ID #|\bamendment\b/i

    def initialize(pdf_bytes)
      @pdf_bytes = pdf_bytes
    end

    def parse
      reader = PDF::Reader.new(StringIO.new(@pdf_bytes))
      text = reader.pages.map(&:text).join("\n")

      results = []

      if (m = text.match(/#{PART1_HEADER.source}(.*?)(?=#{PART2_HEADER.source}|\z)/im))
        txns = extract_transactions(m[1])
        results << { type: 'LCR', contents: txns } if txns.any?
      end

      if (m = text.match(/#{PART2_HEADER.source}(.*)/im))
        txns = extract_transactions(m[1])
        results << { type: 'LCM', contents: txns } if txns.any?
      end

      results
    end

    private

    def extract_transactions(text)
      lines = text.split("\n")

      lines.each_with_index.map do |line, i|
        next unless (m = line.match(TRANSACTION_LINE))

        name = m[2].strip
        amount = m[3].delete(',').to_f

        # Grab the first continuation line as the second part of the name,
        # skipping address/ID lines.
        next_line = lines[i + 1].to_s
        if (cont = next_line.match(/^\s{10,}([A-Za-z].+?)\s{5,}/)) &&
           !next_line.match?(ADDRESS_LINE)
          name = "#{name} #{cont[1].strip}"
        end

        { 'form_Type' => 'F497', 'tran_NamL' => name, 'calculated_Amount' => amount }
      end.compact
    end
  end
end
