# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ElectionCommittee do
  describe '.replace_all_from_csv' do
    let!(:election) { Election.create(slug: 'oakland-2020', location: 'foo', title: 'bar', date: '2020-11-03') }
    let(:committee) do
      {
        'Filer_ID' => '1419466',
        'Filer_NamL' => 'Pass Measure C for Oakland',
        'Ballot Measure' => 'C',
        'Ballot Measure Election' => election.slug,
        'Support or Oppose' => 'S',
        'candidate_controlled_id' => '1234567',
      }
    end
    let(:committees_csv) do
      CSV.generate(headers: committee.keys, write_headers: true) { |csv| csv << committee }
    end

    subject { described_class.replace_all_from_csv(committee_csv: committees_csv) }

    it 'creates an ElectionCommittee with the proper data' do
      ElectionCommittee.destroy_all
      expect { subject }.to change(ElectionCommittee, :count).by(1)
      created_committee = ElectionCommittee.last
      expect(created_committee.ballot_measure).to eq('C')
      expect(created_committee.ballot_measure_election).to eq('oakland-2020')
    end
  end
end
