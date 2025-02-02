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
end
