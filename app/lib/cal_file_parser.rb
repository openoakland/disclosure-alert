# Parse a CAL file (California SOS's format for campaign finance data)
# The format is documented here:
#   https://www.sos.ca.gov/campaign-lobbying/helpful-resources/how-to-file-electronically/california-electronic-filing-format-cal-version-220
#
# This parser only supports:
#   * Nothing yet, but it will eventually (hopefully)
class CalFileParser
  CVR_HEADERS = %w[filer_ID entity_Cd filer_NamL filer_NamF filer_NamT
  filer_NamS report_Num rpt_Date stmt_Type rpt_ID_Num from_Date thru_Date
  elect_Date filer_Adr1 filer_Adr2 filer_City filer_ST filer_ZIP4 filer_Phon
  filer_FAX file_Email mail_Adr1 mail_Adr2 mail_City mail_ST mail_ZIP4 tres_NamL
  tres_NamF tres_NamT tres_NamS tres_Adr1 tres_Adr2 tres_City tres_ST tres_ZIP4
  tres_Phon tres_FAX tres_Email cmtte_Type] +
  # See pg 26 of docs for what these flags mean (different things for different
  # types of committee)
  %w[flag1_YN flag2_YN flag3_YN flag4_YN] +
  # 460, 465, 496
  %w[amendExp_1 amendExp_2 amendExp_3 cand_NamL cand_NamF cand_NamT cand_NamS cand_Adr1 cand_Adr2 cand_City cand_ST cand_ZIP4 cand_Phon cand_FAX cand_Email bal_Name bal_Num bal_Juris office_Cd offic_Dscr juris_Cd juris_Dscr dist_No off_S_H_Cd sup_Opp_Cd]

  RCPT_HEADERS = %w[tran_ID entity_Cd ctrib_NamL ctrib_NamF ctrib_NamT
  ctrib_NamS ctrib_Adr1 ctrib_Adr2 ctrib_City ctrib_ST ctrib_ZIP4 ctrib_Emp
  ctrib_Occ ctrib_Self tran_Type rcpt_Date date_Thru amount cum_YTD hold_Amount
  ctrib_Dscr cmte_ID tres_NamL tres_NamF tres_NamT tres_NamS tres_Adr1 tres_Adr2
  tres_City tres_ST tres_ZIP4 intr_NamL intr_NamF intr_NamT intr_NamS intr_Adr1
  intr_Adr2 intr_City intr_ST intr_ZIP4 intr_Emp intr_Occ intr_Self cand_NamL
  cand_NamF cand_NamT cand_NamS office_Cd offic_Dscr juris_Cd juris_Dscr dist_No
  off_S_H_Cd bal_Name bal_Num bal_Juris sup_Opp_Cd memo_Code memo_RefNo
  bakRef_TID xRef_SchNm xRef_Match int_Rate int_CmteId]

  S497_HEADERS = %w[tran_ID entity_Cd enty_NamL enty_NamF enty_NamT enty_NamS
  enty_Adr1 enty_Adr2 enty_City enty_ST enty_ZIP4 ctrib_Emp ctrib_Occ ctrib_Self
  elec_Date ctrib_Date date_Thru amount cmte_ID cand_NamL cand_NamF cand_NamT
  cand_NamS office_Cd offic_Dscr juris_Cd juris_Dscr dist_No off_S_H_Cd bal_Name
  bal_Num bal_Juris memo_Code Memo_RefNo]

  def initialize(body)
    @body = body
    @cover_sheet = nil
  end

  def parse
    rows = CSV.parse(@body)
    rows.map do |row|
      case row
      in ['SMRY', form_type, *cols]
        {
          'line_Item' => cols[0],
          'amount_A' => cols[1].to_f,
          'form_Type' => form_type
        }
      in ['CVR', form_type, *cols]
        raise 'Multiple CVR rows detected!' unless @cover_sheet.nil?

        @cover_sheet = CVR_HEADERS.zip(cols).to_h
        @cover_sheet
      in ['S496', form_type, *cols] # S496 = Independent Expenditures Made
        {
          'form_Type' => form_type,
          'tran_ID' => cols[0],
          'tran_Amt1' => cols[1].to_f, # "Amount" in PDF
          'exp_Date' => cols[2],
          'date_Thru' => cols[3],
          'tran_Dscr' => cols[4], # "expn_Desc" in PDF
          'memo_Code' => cols[5],
          'memo_RefNo' => cols[6],
        }.tap do |hash|
          # Add fields from cover sheet for backwards-compatibility:
          hash['cand_NamL'] = @cover_sheet['cand_NamL']
          hash['bal_Num'] = @cover_sheet['bal_Num']
          hash['sup_Opp_Cd'] = @cover_sheet['sup_Opp_Cd']
        end
      in ['RCPT', form_type, *cols] # Contributions (460 Schedule A/496P3)
        # TODO: When Tran_Type = X, cols 18 and 19 have different headers.
        RCPT_HEADERS.zip(cols)
          .to_h
          .tap do |hash|
            hash['form_Type'] = form_type
          end
      in ['S497', form_type, *cols] # Late Contributions (F497P1/F497P2)
        S497_HEADERS.zip(cols)
          .to_h
          .tap do |hash|
            hash['form_Type'] = form_type
            hash['amount'] = hash['amount'].to_f

            # Add backwards-compatible fields:
            hash['calculated_Amount'] = hash['amount']
            hash['tran_NamL'] = hash['enty_NamL']
          end
      else
        # Row format not supported
      end
    end.compact
  end
end
