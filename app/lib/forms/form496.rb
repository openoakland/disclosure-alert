# frozen_string_literal: true

module Forms
  # Form 496: Late Independent Expenditure Report
  class Form496 < BaseForm
    def total_contributions_received
      contents
        .find_all { |r| r['form_Type'] == 'F496P3' }
        .sum { |r| r['calculated_Amount'] }
    end

    def total_expenditures_made
      contents
        .find_all { |r| r['form_Type'] == 'F496' }
        .sum { |r| r['tran_Amt1'] }
    end

    def contribution_count
      contents.count { |r| r['form_Type'] == 'F496P3' }
    end

    def expenditure_count
      contents.count { |r| r['form_Type'] == 'F496' }
    end

    def largest_contributions
      contents
        .find_all { |r| r['form_Type'] == 'F496P3' }
        .sort_by { |i| i['calculated_Amount'] }
        .reverse
        .first(3)
    end

    def largest_contributions_amount
      largest_contributions.sum { |r| r['calculated_Amount'] }
    end

    def largest_expenditures
      contents
        .find_all { |r| r['form_Type'] == 'F496' }
        .sort_by { |i| i['tran_Amt1'] }
        .reverse
        .first(3)
    end

    def largest_expenditures_amount
      largest_expenditures.sum { |r| r['tran_Amt1'] }
    end
  end
end
