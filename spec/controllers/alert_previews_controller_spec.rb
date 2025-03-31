# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AlertPreviewsController do
  render_views

  describe '#show' do
    let(:yesterday) { Time.zone.now.to_date.yesterday }
    let!(:filings) do
      [
        Filing.create!(
          id: 100_000,
          filer_id: 333_333,
          filer_name: 'Oakland for better Oaklanders',
          title: 'FPPC Form 496',
          filed_at: yesterday,
          amendment_sequence_number: '0',
          amended_filing_id: nil,
          netfile_agency: NetfileAgency.coak,
          form: 36, # FPPC 496
          contents: [],
        ),
        Filing.create!(
          id: 100_001,
          filer_id: 333_333,
          filer_name: 'Oakland for better Oaklanders',
          title: 'FPPC Form 496',
          filed_at: yesterday,
          amendment_sequence_number: '0',
          amended_filing_id: nil,
          netfile_agency: NetfileAgency.coak,
          form: 36, # FPPC 496
          contents: [],
        ),
      ]
    end

    it "renders successfully" do
      get :show, params: { date: "today" }

      expect(response).to be_successful
      expect(response.body).to include("Oakland for better Oaklanders")
    end
  end
end
