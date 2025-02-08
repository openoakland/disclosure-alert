# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Filing do
  describe '.filed_on_date scope' do
    context 'with filings late in the day' do
      let(:filing_date) { Date.yesterday }
      let(:filed_at) { filing_date.end_of_day }
      let!(:filing) { Filing.create(filed_at: filed_at, netfile_agency: NetfileAgency.coak) }

      it 'returns those filings' do
        expect(Filing.filed_on_date(filing_date)).to include(filing)
      end
    end
  end

  describe '#election_referendum association' do
    let(:filer_id) { '123456' }
    let(:election_name) { 'oakland-2024' }
    let!(:filing) { Filing.create!(filer_id: filer_id, filed_at: Date.yesterday) }
    let!(:election_committee) do
      ElectionCommittee.create!(
        fppc_id: filer_id,
        ballot_measure_election: election_name,
        ballot_measure: 'OK'
      )
    end
    let!(:election_referendum) do
      ElectionReferendum.create!(
        election_name: election_name,
        measure_number: 'OK'
      )
    end

    it 'returns the associated ElectionReferendum' do
      expect(filing.election_referendum)
        .to eq(election_referendum)
    end

    context 'when the committee was contributing for a different election' do
      before do
        election_committee.update(ballot_measure_election: 'other-1111')
      end

      it 'does not return the ElectionReferendum' do
        expect(filing.election_referendum)
          .to eq(nil)
      end
    end
  end
end
