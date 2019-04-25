module AlertMailerHelper
  def format_money(amount)
    '$' + amount.round.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  def form_number_html(form)
    if form.form_name
      sanitize(form.form_name)
        .gsub(/(.{3}) ?([[:alpha:]]+)?/i, '\1 <sub>\2</sub>')
        .gsub(' <sub></sub>', '')
        .html_safe
    elsif form.title =~ /FPPC Form (\d+)/
      $~[1]
    else
      '???'
    end
  end

  # @param title {Hash} Return value from Form#filer_title
  def format_position_title(title)
    second_part =
      if title[:position].match(/(commissioner|\bmember\b)/i)
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
end
