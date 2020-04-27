# frozen_string_literal: true

# An election including its deadlines. Imports from the Open Disclosure
# Candidates spreadsheet.
class Election < ApplicationRecord
  ELECTION_CSV_URL = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=2138925841&single=true&output=csv'
  ELECTION_DEADLINES_CSV_URL = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=996690130&single=true&output=csv'

  has_many :candidates, class_name: 'ElectionCandidate', foreign_key: :election_name, primary_key: :slug
  has_many :referendums, class_name: 'ElectionReferendum', foreign_key: :election_name, primary_key: :slug

  scope :upcoming, (lambda do
    where('date >= ?', Date.today)
      .or(Election.where('deadline_semi_annual_post >= ?', Date.today))
  end)

  def self.replace_all_from_csv(election_csv: ELECTION_CSV_URL,
                                election_deadlines_csv: ELECTION_DEADLINES_CSV_URL)
    election_csv = Net::HTTP.get(URI(election_csv)) if election_csv.start_with?('http')
    election_deadlines_csv = Net::HTTP.get(URI(election_deadlines_csv)) if election_deadlines_csv.start_with?('http')

    elections = CSV.parse(election_csv, headers: :first_row)
    deadlines = CSV.parse(election_deadlines_csv, headers: :first_row).index_by { |r| r['election_name'] }

    transaction do
      destroy_all

      elections.each do |election|
        deadlines_for_election = deadlines[election['name']]

        create(
          slug: election['name'],
          location: election['location'],
          date: Date.parse(election['date']),
          title: election['title'],
          deadline_semi_annual_pre_pre: deadlines_for_election&.fetch('Semi-Annual (Pre Pre)'),
          deadline_semi_annual_pre: deadlines_for_election&.fetch('Semi-Annual (Pre)'),
          deadline_1st_pre_election: deadlines_for_election&.fetch('1st Pre-Election'),
          deadline_2nd_pre_election: deadlines_for_election&.fetch('2nd Pre-Election'),
          deadline_semi_annual_post: deadlines_for_election&.fetch('Semi-Annual (Post-Election)'),
        )
      end
    end
  end

  def locality
    slug.split('-', 2).first
  end
end
