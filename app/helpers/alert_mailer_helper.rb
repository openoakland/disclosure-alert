# frozen_string_literal: true

module AlertMailerHelper
  def format_money(amount)
    '$' + amount.round.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  def format_money_list(items, key:, extra: '', &block)
    sorted_items = items.sort_by { |item| item[key] }.reverse
    listed_items = safe_join(sorted_items[0..2].map do |item|
      content_tag('li') do
        money = item[key]
        raise "Key #{key} not found in money list item" unless money.present?
        format_money(money) + ' – ' + capture_haml(item, &block)
      end
    end, "\n")

    remaining_item_count = sorted_items.length >= 3 ? sorted_items[3..-1].count : 0
    if remaining_item_count > 0
      remaining_item_amount = sorted_items[3..-1].sum { |item| item['tran_Amt1'] || item['calculated_Amount'] }
      listed_items + content_tag('li', "and #{format_money(remaining_item_amount)} in #{format(extra, count: remaining_item_count)}")
    else
      listed_items
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

  def sort_filing_groups(filing_groups)
    filing_groups.sort do |(k1, _), (k2, _)|
      next 1 if k1.match?(/\bother\b/i)
      next -1 if k2.match?(/\bother\b/i)

      k1 <=> k2
    end
  end

  def amended_value_if_different(form, method_name)
    current_value = format_money(form.send(method_name))
    return current_value unless form.amended_filing.present?

    previous_value = format_money(form.amended_filing.send(method_name))
    return previous_value if current_value == previous_value

    "#{current_value} (amended from #{previous_value})"
  end
end
