# frozen_string_literal: true

module Forms
  # Form 496: Late Independent Expenditure Report
  class Form496 < BaseForm
    def contributions
      contents
        .find_all { |r| r['form_Type'] == 'F496P3' }
    end

    def contribution_count
      contributions.count
    end

    def largest_contributions
      contributions
        .sort_by { |i| i['calculated_Amount'] }
        .reverse
        .first(3)
    end

    def total_contributions_received
      contributions
        .sum { |r| r['calculated_Amount'] }
    end


    def largest_contributions_amount
      largest_contributions.sum { |r| r['calculated_Amount'] }
    end

    def expenditures
      contents
        .find_all { |r| r['form_Type'] == 'F496' }
    end

    def total_expenditures_made
      expenditures
        .sum { |r| r['tran_Amt1'] }
    end

    def expenditure_count
      expenditures.count
    end

    def largest_expenditures
      expenditures
        .sort_by { |i| i['tran_Amt1'] }
        .reverse
        .first(3)
    end

    def largest_expenditures_amount
      largest_expenditures.sum { |r| r['tran_Amt1'] }
    end

    # Form 496's can be combined if they are different filings from the same
    # filer, and there is at least one contribution reported on both forms.
    def can_combine_with?(other_form)
      return false unless other_form.is_a?(Forms::Form496)
      return false unless id.nil? || id != other_form.id

      filer_id == other_form.filer_id
    end

    def self.combined_form_class
      Forms::Form496Combined
    end

    def self.combined_form_name
      '496 Combined'
    end
  end
end
