# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Forms::Form460 do
  describe '#spreadsheet_candidate' do
    context 'with models created according to the spreadsheet' do
      let(:filer_id) { 123456789 }
      let!(:election) { Election.create(slug: 'oakland-2020', location: 'foo', title: 'bar', date: '2020-11-03') }
      let(:filing) { Filing.create(form: 30, filer_id: filer_id) }
      let(:form) { Forms.from_filings([filing]).first }
      let!(:election_candidate) { ElectionCandidate.create(election_name: election.slug, fppc_id: filer_id, name: 'Tom McTomface') }

      it 'returns the candidate' do
        expect(form.spreadsheet_candidate).to eq(election_candidate)
      end
    end
  end

  describe '#spreadsheet_committee' do
    context 'with models created according to the spreadsheet' do
      let(:filer_id) { 123456789 }
      let!(:election) { Election.create(slug: 'oakland-2020', location: 'foo', title: 'bar', date: '2020-11-03') }
      let(:filing) { Filing.create(form: 30, filer_id: filer_id) }
      let(:form) { Forms.from_filings([filing]).first }
      let!(:election_committee) { ElectionCommittee.create(fppc_id: filer_id, name: 'Tom McTomface for Mayor') }

      it 'returns the candidate' do
        expect(form.spreadsheet_committee).to eq(election_committee)
      end
    end
  end

  describe '#spreadsheet_referendum' do
    context 'with models created according to the spreadsheet' do
      let(:filer_id) { 123456789 }
      let!(:election) { Election.create(slug: 'oakland-2020', location: 'foo', title: 'bar', date: '2020-11-03') }
      let(:filing) { Filing.create(form: 30, filer_id: filer_id) }
      let(:form) { Forms.from_filings([filing]).first }
      let!(:election_committee) do
        ElectionCommittee.create(
          fppc_id: filer_id,
          name: 'Vote Yes on Proposition Tom',
          ballot_measure: 'T',
          ballot_measure_election: election.slug,
        )
      end
      let!(:election_referendum) do
        ElectionReferendum.create(
          measure_number: 'T',
          election_name: election.slug,
          title: 'Proposition T: Toms for Oakland',
        )
      end

      it 'returns the referendum' do
        expect(form.spreadsheet_referendum).to eq(election_referendum)
      end
    end
  end
end
