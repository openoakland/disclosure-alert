# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Election do
  describe '.replace_all_from_csv' do
    let(:election) do
      {
        'name' => 'oakland-2020',
        'location' => 'Oakland',
        'date' => '2020-11-03',
        'title' => 'Oakland General Election 2020',
      }
    end
    let(:election_csv) do
      CSV.generate(headers: election.keys, write_headers: true) { |csv| csv << election }
    end

    let(:deadlines) do
      {
        'election_name' => 'oakland-2020',
        'Semi-Annual (Pre Pre)' => '2020-01-31',
        'Semi-Annual (Pre)' => '2020-07-31',
        '24-hour Filing Begins' => '2020-08-05',
        '1st Pre-Election' => '2020-09-24',
        '2nd Pre-Election' => '2020-10-22',
        'Semi-Annual (Post-Election)' => '2021-02-01',
      }
    end
    let(:deadlines_csv) do
      CSV.generate(headers: deadlines.keys, write_headers: true) { |csv| csv << deadlines }
    end

    subject do
      described_class.replace_all_from_csv(
        election_csv: election_csv,
        election_deadlines_csv: deadlines_csv,
      )
    end

    it 'creates an Election with the proper dates' do
      Election.destroy_all
      expect { subject }.to change(Election, :count).by(1)
      created_election = Election.last
      expect(created_election.slug).to eq('oakland-2020')
      expect(created_election.date).to eq(Date.new(2020, 11, 3))
      expect(created_election.deadline_semi_annual_pre).to eq(Date.new(2020, 7, 31))
    end

    describe 'when the election_csv is a URL' do
      let(:election_csv_url) { 'http://example.com/example.csv' }

      subject do
        described_class.replace_all_from_csv(
          election_csv: election_csv_url,
          election_deadlines_csv: deadlines_csv,
        )
      end

      before do
        allow(URI).to receive(:open).with(election_csv_url)
          .and_return(StringIO.new(election_csv))
      end

      it 'downloads the election_csv' do
        Election.destroy_all
        expect { subject }.to change(Election, :count).by(1)
        created_election = Election.last
        expect(created_election.slug).to eq('oakland-2020')
        expect(created_election.date).to eq(Date.new(2020, 11, 3))
        expect(created_election.deadline_semi_annual_pre).to eq(Date.new(2020, 7, 31))
      end
    end
  end
end
