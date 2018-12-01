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
end
