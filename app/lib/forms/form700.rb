module Forms
  class Form700 < BaseXMLForm
    LEGEND = {
      fair_market_value: [
        '$2,000-$10,000', '$10,001-$100,000', '$100,001-$1,000,000', 'Over $1,000,000'
      ].freeze,
      fair_market_value_schedule_a_2: [
        '$0-$1,999', '$2,000-$10,000', '$10,001-$100,000', '$100,001-$1,000,000', 'Over $1,000,000'
      ].freeze,
      gross_income_received: [
        '$0-$499', '$500-$1,000', '$1,001-$10,000', '$10,001-$100,000', 'Over $100,000'
      ].freeze,
      nature_of_interest: [
        'Ownership/Deed of Trust', 'Easement', 'Leasehold', 'Other'
      ].freeze,
      nature_of_investment: [
        'Partnership', 'Sole Proprietorship', 'Other'
      ],
      gross_income_received_schedule_c_1: [
        'No Income - Business Position Only', '$500-$1,000', '$1,001-$10,000', '$10,001-$100,000', 'Over $100,000'
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

    def not_efiled?
      @xml.blank?
    end

    def filer_name
      return super unless @xml.present?

      [@xml.xpath('//disclosure/cover/first_name'), @xml.xpath('//disclosure/cover/last_name')].join(' ')
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
  end
end
