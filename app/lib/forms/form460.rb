# frozen_string_literal: true

module Forms
  class Form460 < BaseForm
    def total_contributions_received
      contents_row('F460', '5')['amount_A']
    end

    def total_expenditures_made
      contents_row('F460', '11')['amount_A']
    end

    private

    def contents_row(form_type, line_item)
      @filing.contents.detect { |r| r['form_Type'] == form_type && r['line_Item'] == line_item }
    end
  end
end
