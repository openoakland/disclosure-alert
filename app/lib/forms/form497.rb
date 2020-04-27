# frozen_string_literal: true

module Forms
  # Form 497: Late Contributions Received/Made
  class Form497 < BaseForm
    def total_amount
      contents.sum { |r| r['calculated_Amount'] }
    end

    def contribution_count
      contents.length
    end

    def largest_three
      contents
        .sort_by { |i| i['calculated_Amount'] }
        .reverse
        .first(3)
    end

    def largest_three_total_amount
      largest_three.map { |i| i['calculated_Amount'] }.sum
    end
  end
end
