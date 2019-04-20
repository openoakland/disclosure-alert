# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Filing do
  describe '.filed_on_date scope' do
    context 'with filings late in the day' do
      let(:filing_date) { Date.yesterday }
      let(:filed_at) { filing_date.end_of_day }
      let!(:filing) { Filing.create(filed_at: filed_at) }

      it 'returns those filings' do
        expect(Filing.filed_on_date(filing_date)).to include(filing)
      end
    end
  end
end
