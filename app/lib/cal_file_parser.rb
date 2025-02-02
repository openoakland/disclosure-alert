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
      puts 'Looks like a F460'
    end

    rows.map do |row|
      case row
      in ['SMRY', form_type, *cols]
        { 'line_Item' => cols[0], 'amount_A' => cols[1].to_f, 'form_Type' => form_type }
      else
        # Row format not supported
      end
    end.compact
  end
end
