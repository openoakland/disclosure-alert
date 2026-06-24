# frozen_string_literal: true

require 'pdf-reader'

module Netfile
  # Extracts Form 460 summary totals from the PDF filing.
  #
  # The Connect2 structured-data API is gone, but the PDF image endpoint still
  # works. This parser pulls the three summary line items needed to render the
  # Form 460 section of the alert email, producing the same [{form_Type,
  # line_Item, amount_A}] array that Form460#contents_row expects.
  class Form460PdfParser
    # The PDF text concatenates label words without spaces, e.g.
    # "TOTALCONTRIBUTIONS RECEIVED" and "TOTALEXPENDITURESMADE". Use \s* to
    # tolerate both concatenated and spaced variants.
    #
    # Lines 5 and 11: the Column A amount is on the same line as the label.
    # Line 16: the multi-column layout causes pdf-reader to extract the amount
    # on its own line immediately BEFORE the label (right-column boilerplate
    # text is interleaved between them in the content stream).
    FORWARD_LINES = {
      '5'  => /TOTAL\s*CONTRIBUTIONS?\s*RECEIVED/i,
      '11' => /TOTAL\s*EXPENDITURES?\s*MADE/i,
    }.freeze

    BACKWARD_LINES = {
      '16' => /16\.\s*ENDING\s*CASH\s*BALANCE/i,
    }.freeze

    def initialize(pdf_bytes)
      @pdf_bytes = pdf_bytes
    end

    # Returns an array of three row hashes compatible with Form460#contents_row.
    # Zero amounts absent from the PDF text default to 0.0.
    def parse
      reader = PDF::Reader.new(StringIO.new(@pdf_bytes))
      text = reader.pages.map(&:text).join("\n")
      parse_summary_lines(text)
    end

    private

    def parse_summary_lines(text)
      forward = FORWARD_LINES.map do |line_item, pattern|
        match = text.match(/#{pattern.source}[^\n]*?([\d,]+\.\d{2})/i)
        amount = match ? match[1].delete(',').to_f : 0.0
        { 'form_Type' => 'F460', 'line_Item' => line_item, 'amount_A' => amount }
      end

      backward = BACKWARD_LINES.map do |line_item, pattern|
        # Amount is on the line immediately before the label.
        match = text.match(/([\d,]+\.\d{2})[^\n]*\n[^\n]*#{pattern.source}/i)
        amount = match ? match[1].delete(',').to_f : 0.0
        { 'form_Type' => 'F460', 'line_Item' => line_item, 'amount_A' => amount }
      end

      forward + backward
    end
  end
end
