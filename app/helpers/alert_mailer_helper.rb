# frozen_string_literal: true

module AlertMailerHelper
  # Any forms not in this array will be sorted after all forms listed
  # here.
  #
  # Any forms with "Other" in the name will be listed after those.
  FORM_SORT_ORDER = [
    "Forms::Form497Combined",
    "Forms::Form497",
    "Forms::Form496Combined",
    "Forms::Form496",
    "Forms::Form460",
    "Forms::Form410",
  ]

  def format_money(amount)
    '$' + amount.round.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  def format_money_list(items, key:, extra: '', &block)
    sorted_items = items.sort_by { |item| item[key] }.reverse

    # Take the top 3 items always, and any additional items until the item is
    # 20% the magnitude of the 3rd item. If there is only one item left (the
    # 4th), take it because it doesn't make any sense to say "and 1 other
    # contribution".  This is highly arbitrary and just designed to take a crude
    # stab at hiding some of the more irrelevant entries.
    top_items = sorted_items.each_with_index.take_while do |item, i|
      i < 3 ||
        i == (sorted_items.length - 1) ||
        (
          item[key] > 250 &&
          sorted_items.length >= 3 &&
          item[key] > sorted_items[2][key] * 0.2
        )
    end
    top_items_html = safe_join(top_items.map do |item, _i|
      content_tag('li') do
        money = item[key]
        raise "Key #{key} not found in money list item" unless money.present?
        format_money(money) + ' – ' + capture_haml(item, &block)
      end
    end, "\n")

    remaining_items = if sorted_items.length > top_items.length
                        sorted_items[(top_items.last[1] + 1)..-1]
                      else
                        []
                      end
    remaining_item_count = remaining_items.count

    if remaining_item_count.positive?
      remaining_item_amount = remaining_items.sum { |item| item[key] }
      top_items_html + content_tag(
        'li',
        "and #{format_money(remaining_item_amount)} in " +
        format(extra, count: remaining_item_count),
      )
    else
      top_items_html
    end
  end

  def form_number_html(form)
    if form.form_name
      sanitize(form.form_name)
        .gsub(/(.{3}) ?([[:alpha:]]+)?/i, '\1 <sub>\2</sub>')
        .gsub(' <sub></sub>', '')
        .html_safe
    else
      '???'
    end
  end

  # @param title {Hash} Return value from Form#filer_title
  def format_position_title(title)
    second_part =
      if title[:position].match?(/(commissioner|\bmember\b)/i)
        title[:division_board_district] || title[:agency]
      else
        title[:agency].try(:titleize)
      end

    [
      title[:position],
      second_part,
    ].compact.join(', ')
  end

  def sort_forms(forms)
    sorted_last = FORM_SORT_ORDER.length - 1

    forms.sort_by do |f|
      (FORM_SORT_ORDER.index(f.class.name) || sorted_last) +
        (f.form_name.nil? ? 0.5 : 0)
    end
  end

  def amended_value_if_different(form, method_name)
    current_value = format_money(form.send(method_name))
    return current_value unless form.amended_filing.present?

    previous_value = format_money(form.amended_filing.send(method_name))
    return previous_value if current_value == previous_value

    "#{current_value} (amended from #{previous_value})"
  end

  def deduplicate_deadlines(deadlines)
    deadlines
      .group_by { |deadline| deadline.date }
      .transform_values do |deadlines_with_date|
        # Keep the deduplicated one, unless the one we're looking at
        # has a netfile_agency_id
        deadlines_with_date.reduce(deadlines_with_date.first) do |deduplicated, deadline|
          deadline.netfile_agency_id.present? ? deadline : deduplicated
        end
      end
      .values
      .flatten
  end

  def format_value_range(value_range)
    if value_range.is_a?(String)
      value_range
    elsif value_range.max == Float::INFINITY
      "Over #{format_money(value_range.min - 1)}"
    else
      "#{format_money(value_range.min)}–#{format_money(value_range.max)}"
    end
  end

  def format_investments_list(investments)
    # See format_money_list for inspiration
    sorted_items = investments.sort_by { |investment| investment["fair_market_value"].max }.reverse

    # Take the top 5 items, or 6 if there are only 6 items (since it doesn't
    # make sense to say "and 1 other item").
    top_item_length = sorted_items.length == 6 ? 6 : 5
    top_items = sorted_items[0...top_item_length]
    top_items_html = safe_join(top_items.map do |investment|
      content_tag("li") do
        investment["name_of_business_entity"] +
        ": " +
        format_value_range(investment["fair_market_value"])
      end
    end, "\n")

    remaining_items = Array(sorted_items[(top_item_length + 1)..])
    remaining_item_count = remaining_items.count
    if remaining_item_count.positive?
      remaining_items_min, remaining_items_max = remaining_items.reduce([0, 0]) do |(min, max), investment|
        [min + investment["fair_market_value"].min, max + investment["fair_market_value"].max]
      end
      remaining_items_range = Forms::Form700::ValueRange.new(remaining_items_min, remaining_items_max) 

      top_items_html + content_tag(
        'li',
        "and #{format_value_range(remaining_items_range)} in " +
        format("%{count} other items", count: remaining_item_count),
      )
    else
      top_items_html
    end
  end

  def view_filing_netfile_url(filing_id)
    "https://www.netfile.com/Connect2/api/json/reply/Image?filingId=#{filing_id}"
  end
end
