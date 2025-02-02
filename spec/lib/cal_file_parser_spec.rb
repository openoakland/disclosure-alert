require 'rails_helper'

RSpec.describe CalFileParser do
  let(:parser) { CalFileParser.new(fixture) }

  describe 'parsing a 460' do
    let(:fixture) { File.read(Rails.root.join('spec', 'fixtures', 'cal', 'F460-212406069.txt')) }

    it 'returns the line numbers and amounts from rows' do
      results = parser.parse
      expect(results).to be_a(Array)
      expect(results).to include('form_Type' => 'F460', 'line_Item' => '5', 'amount_A' => 30000.00)
      expect(results).to include('form_Type' => 'F460', 'line_Item' => '11', 'amount_A' => 26092.00)
      expect(results).to include('form_Type' => 'F460', 'line_Item' => '16', 'amount_A' => 6303.00)
      expect(results).to include('form_Type' => 'A', 'line_Item' => '1', 'amount_A' => 30_000.00)
      expect(results).to include('form_Type' => 'E', 'line_Item' => '4', 'amount_A' => 23_697.00)
    end
  end

  describe 'parsing a 496' do
    let(:fixture) { File.read(Rails.root.join('spec', 'fixtures', 'cal', 'F496-212424488.txt')) }

    it 'parses the cover sheet' do
      results = parser.parse
      expect(results).to include(hash_including(
        'filer_NamL' => 'OAKLANDERS FOR COMMON SENSE, UNITED TO FIRE CARROLL FIFE AND ELECT WARREN LOGAN FOR CITY COUNCIL 2024'
      ))
    end

    it 'parses S496 rows (independent expenditures made)' do
      results = parser.parse
      expect(results).to include(hash_including('form_Type' => 'F496', 'tran_Amt1' => 15000.00, 'tran_Dscr' => 'ELECTRONIC MEDIA ADS'))
      expect(results).to include(hash_including('form_Type' => 'F496', 'tran_Amt1' => 15000.00, 'tran_Dscr' => 'ONLINE VIDEO ADS'))
    end

    it 'parses F496P3 rows (contributions >$100 received)' do
      results = parser.parse
      expect(results).to include(hash_including('form_Type' => 'F496', 'tran_Amt1' => 15000.00, 'tran_Dscr' => 'ONLINE VIDEO ADS'))
    end
  end
end
