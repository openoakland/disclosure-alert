# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Forms::Form497 do
  let(:contents) do
    [
      { "form_Type"=>"F497P1", "tran_NamL"=>"One", "calculated_Amount"=>40000.0 },
      { "form_Type"=>"F497P1", "tran_NamL"=>"Two", "calculated_Amount"=>490.0 },
      { "form_Type"=>"F497P1", "tran_NamL"=>"Three", "calculated_Amount"=>327.75 },
      { "form_Type"=>"F497P1", "tran_NamL"=>"Four", "calculated_Amount"=>1805.7 },
      { "form_Type"=>"F497P2", "tran_NamL"=>"Five", "calculated_Amount"=>5872.64 },
      { "form_Type"=>"F497P2", "tran_NamL"=>"Six", "calculated_Amount"=>6185.05 }
    ]
  end
  let(:filing) { Filing.new(title: 'FPPC Form 497 (10/14/2022)', form: 39, contents: contents) }
  let(:form) { Forms.from_filings([filing]).first }

  describe '#amount_contributions_received' do
    it 'sums up the F497P1 amounts' do
      expect(form.amount_contributions_received).to eq(42_623.45)
    end
  end

  describe '#amount_contributions_made' do
    it 'sums up the F497P2 amounts' do
      expect(form.amount_contributions_made).to eq(12_057.69)
    end
  end
end
