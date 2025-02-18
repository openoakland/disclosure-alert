# frozen_string_literal: true

module Forms
  # Form 497: Daily Contributions Received/Made
  class Form497 < BaseForm
    def amount_contributions_received
      contributions_received.sum { |r| r['calculated_Amount'] }
    end

    def amount_contributions_made
      contributions_made.sum { |r| r['calculated_Amount'] }
    end

    def count_contributions_received
      contributions_received.length
    end

    def count_contributions_made
      contributions_made.length
    end

    def contributions_received
      contents.find_all { |r| r['form_Type'] == 'F497P1' }
    end

    def contributions_made
      contents.find_all { |r| r['form_Type'] == 'F497P2' }
    end

    # Form 497's can be combined if they are different filings from the same
    # filer, and there is at least one contribution reported on both forms.
    def can_combine_with?(other_form)
      return false unless other_form.is_a?(Forms::Form497)
      return false unless id.nil? || id != other_form.id

      filer_id == other_form.filer_id
    end

    def self.combined_form_class
      Forms::Form497Combined
    end

    def self.combined_form_name
      '497 Combined'
    end
  end
end
