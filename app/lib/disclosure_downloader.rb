# frozen_string_literal: true

class DisclosureDownloader
  def initialize; end

  def download
    latest = Filing.order(filed_at: :desc).first
    puts '==================================================================='
    puts 'Beginning State:'
    puts
    puts "Filings: #{Filing.count}"
    puts "Latest: #{latest&.filed_at}"
    puts '==================================================================='

    netfile = Netfile::Client.new
    netfile.each_filing do |json|
      filing = Filing.from_json(json)

      if filing.new_record?
        puts "Syncing new filing: #{filing.inspect}"
      end

      break if latest && latest == filing
      break if Date.today - filing.filed_at.to_date > 14

      contents =
        case filing.form_name
        when '460'
          netfile
            .fetch_summary_contents(filing.id)
            .map { |row| row.slice('form_Type', 'line_Item', 'amount_A') }
        when '497 LCR', '497 LCM'
          netfile
            .fetch_transaction_contents(filing.id)
            .map { |row| row.slice('form_Type', 'tran_NamL', 'calculated_Amount') }
        end

      filing.update_attribute(:contents, contents)
    end

    latest = Filing.order(filed_at: :desc).first
    puts '==================================================================='
    puts 'Ending State:'
    puts
    puts "Filings: #{Filing.count}"
    puts "Latest: #{latest&.filed_at}"
    puts '==================================================================='
  end
end
