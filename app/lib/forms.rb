module Forms
  def self.from_filings(filing_array)
    filing_array.map do |filing|
      case filing.form_name
      when '460'
        Forms::Form460.new(filing)
      when '700'
        Forms::Form700.new(filing)
      else
        Forms::BaseForm.new(filing)
      end
    end
  end

  class BaseForm
    delegate :id, :filer_id, :filer_name, :title, :filed_at,
             :amendment_sequence_number, :amended_filing_id, :form, :form_name,
             :contents, :contents_xml,
             to: :@filing

    def initialize(filing)
      @filing = filing
    end
  end

  class BaseXMLForm < BaseForm
    def initialize(filing)
      super

      @xml = Nokogiri::XML(contents_xml, &:noblanks) if contents_xml.present?
    end
  end
end
