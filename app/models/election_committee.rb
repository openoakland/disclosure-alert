require 'open-uri'

class ElectionCommittee < ApplicationRecord
  COMMITTEE_CSV_URL = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=1015408103&single=true&output=csv'

  def self.replace_all_from_csv(committee_csv: COMMITTEE_CSV_URL)
    committee_csv = URI.open(committee_csv).read if committee_csv.start_with?('http')
    committees = CSV.parse(committee_csv, headers: :first_row)
    elections = Election.where(slug: committees.map { |c| c['Ballot Measure Election'] }).index_by(&:slug)

    transaction do
      destroy_all
      committees.each do |committee|
        election = elections[committee['Ballot Measure Election']]
        next unless election

        create(
          name: committee['Filer_NamL'],
          fppc_id: committee['Filer_ID'],
          candidate_controlled_id: committee['candidate_controlled_id'],
          support_or_oppose: committee['Support or Oppose'],
          ballot_measure: committee['Ballot Measure'],
          ballot_measure_election: committee['Ballot Measure Election'],
        )
      end
    end
  end
end
