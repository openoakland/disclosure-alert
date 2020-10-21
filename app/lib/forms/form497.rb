# frozen_string_literal: true

module Forms
  # Form 497: Late Contributions Received/Made
  class Form497 < BaseForm
    def total_amount
      contributions.sum { |r| r['calculated_Amount'] }
    end

    def contribution_count
      contributions.length
    end

    def contributions
      contents
    end
  end
end
