require 'open-uri'

class ElectionReferendum < ApplicationRecord
  REFERENDUM_CSV_URL = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=608094632&single=true&output=csv'

  belongs_to :election, foreign_key: :election_name, primary_key: :slug
  has_many :election_committees, -> do
    where('election_committees.ballot_measure_election = election_referendums.election_name')
  end, primary_key: :measure_number, foreign_key: :ballot_measure

  def self.replace_all_from_csv(referendum_csv: REFERENDUM_CSV_URL)
    referendum_csv = URI.open(referendum_csv).read if referendum_csv.start_with?('http')

    referendums = CSV.parse(referendum_csv, headers: :first_row)
    elections = Election.where(slug: referendums.map { |c| c['election_name'] }).index_by(&:slug)

    transaction do
      destroy_all
      referendums.each do |referendum|
        election = elections[referendum['election_name']]
        next unless election

        create(
          election_name: referendum['election_name'],
          measure_number: referendum['Measure number'],
          title: referendum['Short Title'],
          full_title: referendum['Full Title'],
        )
      end
    end
  end

  def opendisclosure_url
    "https://www.opendisclosure.io/referendum/#{election.locality}/#{election.date}/#{Slugify.slug(title)}"
  end
end
