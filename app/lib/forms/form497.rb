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
  end
end
