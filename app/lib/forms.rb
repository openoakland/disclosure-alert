# frozen_string_literal: true

module Forms
  def self.from_filings(filing_array)
    filing_array.map do |filing|
      case filing.form.to_i
      when 23
        Forms::Form410.new(filing, name: '410')
      when 30
        Forms::Form460.new(filing, name: '460')
      when 36
        Forms::Form496.new(filing, name: '496')
      when 38 # LCM = Late Contributions Made
        Forms::Form497.new(filing, name: '497 LCM')
      when 39 # LCR = Late Contributions Received
        Forms::Form497.new(filing, name: '497 LCR')
      when 199, 215, 220, 228, 254
        Forms::Form700.new(filing, name: '700')
      when 236 # LBQ = Oakland Lobbyist Quartery Report
        Forms::BaseForm.new(filing, name: 'LBQ')
      when 235 # LBR = Oakland Lobbyist Registration
        Forms::BaseForm.new(filing, name: 'LBR')
      else
        guessed_form_name = filing.title.match(/FPPC Form (\d+)/) ? $~[1] : nil

        if filing.form.to_i == 0 && guessed_form_name == '700'
          Forms::Form700.new(filing, name: guessed_form_name)
        else
          Forms::BaseForm.new(filing, name: guessed_form_name)
        end
      end
    end
  end

  class BaseForm
    delegate :id, :filer_id, :title, :filed_at, :amended_filing_id, :form,
      :contents, :contents_xml, to: :@filing
    attr_reader :form_name

    def initialize(filing, name: nil)
      @filing = filing
      @form_name = name
    end

    # Override in a subclass if a better name can be presented to the user.
    def filer_name
      @filing.filer_name
    end

    # Override in a subclass
    # @retun {Hash?} Returns a hash with keys position, agency, and
    # division_board_district.
    def filer_title; end

    # I18n key to describe the Form
    def i18n_key
      return 'forms.unknown' unless @filing.form_name.present?
      key = "forms.#{@filing.form_name.delete(' ')}"
      return 'forms.unknown' unless I18n.exists?(key)

      key
    end

    def amended_filing
      return unless @filing.amended_filing

      self.class.new(@filing.amended_filing, name: @filing.form_name)
    end

    def spreadsheet_candidate
      @filing.election_candidates.last
    end

    def spreadsheet_committee
      @filing.election_committee
    end

    def spreadsheet_referendum
      @filing.election_referendum
    end
  end

  class BaseXMLForm < BaseForm
    def initialize(filing, name: nil)
      super

      @xml = Nokogiri::XML(contents_xml, &:noblanks) if contents_xml.present?
    end
  end
end
