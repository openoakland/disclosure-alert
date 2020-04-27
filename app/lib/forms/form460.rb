# frozen_string_literal: true

module Forms
  # Form 460: Campaign Disclosure Statement
  class Form460 < BaseForm
    TITLE_REGEX = %r{FPPC Form 460 \((?<start_month>\d+)/(?<start_day>\d+)/(?<start_year>\d+) - (?<end_month>\d+)/(?<end_day>\d+)/(?<end_year>\d+)\)} # rubocop:disable LineLength

    def total_contributions_received
      contents_row('F460', '5')['amount_A']
    end

    def total_expenditures_made
      contents_row('F460', '11')['amount_A']
    end

    def ending_cash_balance
      contents_row('F460', '16')['amount_A']
    end

    def start_date
      match = @filing.title.match(TITLE_REGEX)
      return unless match
      Date.new(match[:start_year], match[:start_month], match[:start_day])
    end

    def end_date
      match = @filing.title.match(TITLE_REGEX)
      return unless match
      Date.new(match[:end_year].to_i, match[:end_month].to_i, match[:end_day].to_i)
    end

    private

    def contents_row(form_type, line_item)
      @filing.contents.detect { |r| r['form_Type'] == form_type && r['line_Item'] == line_item }
    end
  end
end
