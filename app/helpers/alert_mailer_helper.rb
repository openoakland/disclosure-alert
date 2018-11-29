module AlertMailerHelper
  def format_money(amount)
    '$' + amount.round.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
