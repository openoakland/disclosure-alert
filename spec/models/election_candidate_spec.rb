# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ElectionCandidate do
  describe '.replace_all_from_csv' do
    let(:election) { Election.create(slug: 'oakland-2020', location: 'foo', title: 'bar', date: '2020-11-03') }
    let(:candidate) do
      {
        'election_name' => election.slug,
        'Candidate' => 'Rebecca Kaplan',
        'FPPC#' => '1419466',
        'Committee Name' => 'Re-Elect Rebecca Kaplan for City Council 2020',
        'Aliases' => '',
        'Office' => 'City Council At-Large',
        'Incumbent' => 'TRUE',
      }
    end
    let(:candidate_csv) do
      CSV.generate(headers: candidate.keys, write_headers: true) { |csv| csv << candidate }
    end

    subject { described_class.replace_all_from_csv(candidate_csv: candidate_csv) }

    it 'creates an ElectionCandidate with the proper data' do
      ElectionCandidate.destroy_all
      expect { subject }.to change(ElectionCandidate, :count).by(1)
      created_candidate = ElectionCandidate.last
      expect(created_candidate.election_name).to eq(election.slug)
      expect(created_candidate.name).to eq('Rebecca Kaplan')
      expect(created_candidate.incumbent).to eq(true)
    end
  end
end
