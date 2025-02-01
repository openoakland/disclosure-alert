# Parse a CAL file (California SOS's format for campaign finance data)
# The format is documented here:
#   https://www.sos.ca.gov/campaign-lobbying/helpful-resources/how-to-file-electronically/california-electronic-filing-format-cal-version-220
#
# This parser only supports:
#   * Nothing yet, but it will eventually (hopefully)
class CalFileParser
  def initialize(body)
    @body = body
  end

  def parse
    rows = CSV.parse(@body)
    if rows[1][0] == 'CVR' && rows[1][1] == 'F460'
      puts "Looks like a F460"
    end

    rows.map do |row|
      record_type = row.shift
      form_type = row.shift
      
      if record_type == 'SMRY' && form_type == 'F460'
        # Do I need to subdivide this into form_type = 'F460'?
        %w[line_Item amount_A form_Type].zip(row).to_h.tap do |hash|
          hash['form_Type'] = form_type
          hash['amount_A'] = hash['amount_A'].to_f
        end
      end
    end.compact
  end
end
