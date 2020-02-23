# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ElectionReferendum do
  describe '.replace_all_from_csv' do
    let(:election) { Election.create(slug: 'oakland-march-2020', location: 'foo', title: 'bar', date: '2020-11-03') }

    let(:referendum) do
      {
        'election_name' => 'oakland-march-2020',
        'Measure number' => 'Q',
        'Short Title' => 'Some Measure name here',
        'Full Title' => 'Full measure description',
      }
    end
    let(:referendum_csv) do
      CSV.generate(headers: referendum.keys, write_headers: true) { |csv| csv << referendum }
    end

    subject do
      described_class.replace_all_from_csv(
        referendum_csv: referendum_csv,
      )
    end

    it 'creates an ElectionReferendum with the proper data' do
      ElectionReferendum.destroy_all
      expect { subject }.to change(ElectionReferendum, :count).by(1)
      created_referendum = ElectionReferendum.last
      expect(created_referendum.election_name).to eq(election.slug)
      expect(created_referendum.title).to eq('Some Measure name here')
      expect(created_referendum.full_title).to eq('Full measure description')
    end
  end
end
