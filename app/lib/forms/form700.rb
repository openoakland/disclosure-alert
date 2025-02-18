module Forms
  class Form700 < BaseXMLForm
    ValueRange = Struct.new(:min, :max)

    LEGEND = {
      fair_market_value: [
        ValueRange.new(2_000, 10_000),
        ValueRange.new(10_001, 100_000),
        ValueRange.new(100_001, 1_000_000),
        ValueRange.new(1_000_001, Float::INFINITY),
      ].freeze,
      fair_market_value_schedule_a_2: [
        ValueRange.new(0, 1_999),
        ValueRange.new(2_000, 10_000),
        ValueRange.new(10_001, 100_000),
        ValueRange.new(100_001, 1_000_000),
        ValueRange.new(1_000_001, Float::INFINITY)
      ].freeze,
      gross_income_received: [
        ValueRange.new(0, 499),
        ValueRange.new(500, 1_000),
        ValueRange.new(1_001, 10_000),
        ValueRange.new(10_001, 100_000),
        ValueRange.new(100_001, Float::INFINITY),
      ].freeze,
      nature_of_interest: [
        'Ownership/Deed of Trust', 'Easement', 'Leasehold', 'Other'
      ].freeze,
      nature_of_investment: [
        'Partnership', 'Sole Proprietorship', 'Other'
      ],
      gross_income_received_schedule_c_1: [
        'No Income - Business Position Only',
        ValueRange.new(500, 1_000),
        ValueRange.new(1_001, 10_000),
        ValueRange.new(10_001, 100_000),
        ValueRange.new(100_001, Float::INFINITY)
      ].freeze,
      reason_for_income: [
        'Salary', "Spouse's or registered domestic partner's income", 'Partnership',
        'Sale', 'Loan Repayment', 'Commission', 'Rental income', 'Other'
      ].freeze,
      business_type: [
        'Trust', 'Business Entity',
      ].freeze,
      type_of_payment: [
        'Gift', 'Income',
      ].freeze,
    }.with_indifferent_access.freeze

    def self.title_from_office(office)
      {
        position: office['position'],
        agency: office['agency'],
        division_board_district: office['division_board_district'],
      }
    end

    def not_efiled?
      @xml.blank?
    end

    def filer_name
      return super unless @xml.present?

      [@xml.xpath('//disclosure/cover/first_name'), @xml.xpath('//disclosure/cover/last_name')].join(' ')
    end

    def filer_title
      return super unless @xml.present? && offices.any?

      Forms::Form700.title_from_office(offices[0])
    end

    def offices
      return [] unless @xml.present?

      @xml.xpath('//disclosure/cover/offices/office').map do |office|
        office.children.each_with_object({}) do |el, hash|
          hash[el.name] = el.text
        end
      end
    end

    def schedule_a1
      return [] unless @xml.present?

      @xml.xpath('//disclosure/schedule_a_1s/schedule_a_1').map do |schedule|
        schedule.children.each_with_object({}) do |el, hash|
          hash[el.name] = if LEGEND.include?(el.name)
                            LEGEND[el.name][el.text.to_i - 1]
                          else
                            el.text
                          end
        end
      end
    end

    def schedule_a2
      return [] unless @xml.present?

      @xml.xpath('//disclosure/schedule_a_2s/schedule_a_2').map do |schedule|
        schedule.children.each_with_object({}) do |el, hash|
          hash[el.name] = if LEGEND.include?(el.name)
                            LEGEND[el.name][el.text.to_i - 1]
                          else
                            el.text
                          end
        end
      end
    end

    def schedule_b
      return [] unless @xml.present?

      @xml.xpath('//disclosure/schedule_bs/schedule_b').map do |schedule|
        schedule.children.each_with_object({}) do |el, hash|
          hash[el.name] = if LEGEND.include?(el.name)
                            LEGEND[el.name][el.text.to_i - 1]
                          else
                            el.text
                          end
        end
      end
    end

    def schedule_c1
      return [] unless @xml.present?

      @xml.xpath('//disclosure/schedule_c_1s/schedule_c_1').map do |schedule|
        schedule.children.each_with_object({}) do |el, hash|
          hash[el.name] = if LEGEND.include?(el.name)
                            LEGEND[el.name][el.text.to_i - 1]
                          else
                            el.text
                          end
        end
      end
    end

    def schedule_d
      return [] unless @xml.present?

      @xml.xpath('//disclosure/schedule_ds/schedule_d').map do |schedule|
        schedule.children.each_with_object({}) do |el, hash|
          hash[el.name] = if LEGEND.include?(el.name)
                            LEGEND[el.name][el.text.to_i - 1]
                          elsif el.name == 'gifts'
                            el.xpath('gift').map do |g|
                              {
                                'amount' => g.xpath('amount/text()').to_s.to_f,
                                'description' => g.xpath('description/text()').to_s,
                                'gift_date' => g.xpath('gift_date/text()').to_s,
                              }
                            end
                          else
                            el.text
                          end
        end
      end
    end

    def schedule_e
      return [] unless @xml.present?

      @xml.xpath('//disclosure/schedule_es/schedule_e').map do |schedule|
        schedule.children.each_with_object({}) do |el, hash|
          hash[el.name] = if LEGEND.include?(el.name)
                            LEGEND[el.name][el.text.to_i - 1]
                          else
                            el.text
                          end
        end
      end
    end

    def no_reportable_interests?
      return unless @xml.present?

      [
        @xml.xpath('//schedule_a_1s/@count'),
        @xml.xpath('//schedule_a_2s/@count'),
        @xml.xpath('//schedule_bs/@count'),
        @xml.xpath('//schedule_c_1s/@count'),
        @xml.xpath('//schedule_c_2s/@count'),
        @xml.xpath('//schedule_ds/@count'),
        @xml.xpath('//schedule_es/@count'),
      ].map(&:first).map(&:value).map(&:to_i).sum == 0
    end

    def total_value_range
      return ValueRange.new(0, 0) if no_reportable_interests?

      total = ValueRange.new(0, 0)
      schedule_a1.each do |investment|
        total.min += investment["fair_market_value"].min
        total.max += investment["fair_market_value"].max
      end

      schedule_a2.each do |investment|
        total.min += investment["fair_market_value_schedule_a_2"].min
        total.max += investment["fair_market_value_schedule_a_2"].max
      end

      schedule_b.each do |real_property|
        total.min += real_property["fair_market_value"].min
        total.max += real_property["fair_market_value"].max
      end

      schedule_c1.each do |income_or_loan|
        next if income_or_loan["gross_income_received_schedule_c_1"].is_a?(String)

        total.min += income_or_loan["gross_income_received_schedule_c_1"].min
        total.max += income_or_loan["gross_income_received_schedule_c_1"].max
      end

      schedule_d.each do |gift_entry|
        gift_entry["gifts"].each do |gift|
          total.min += gift["amount"]
          total.max += gift["amount"]
        end
      end

      schedule_e.each do |travel_gift|
        total.min += travel_gift["amount"].to_f
        total.max += travel_gift["amount"].to_f
      end

      total
    end

    def minimize?
      total_value_range.max < 150_000
    end
  end
end
