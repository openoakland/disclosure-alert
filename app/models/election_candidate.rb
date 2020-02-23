# frozen_string_literal: true

# A human candidate running in an election. Imports from the Open Disclosure
# Candidates spreadsheet.
class ElectionCandidate < ApplicationRecord
  CANDIDATE_CSV_URL = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=0&single=true&output=csv'

  def self.replace_all_from_csv(candidate_csv: CANDIDATE_CSV_URL)
    candidate_csv = Net::HTTP.get(URI(candidate_csv)) if candidate_csv.start_with?('http')
    candidates = CSV.parse(candidate_csv, headers: :first_row)
    elections = Election.where(slug: candidates.map { |c| c['election_name'] }).index_by(&:slug)

    transaction do
      destroy_all
      candidates.each do |candidate|
        election = elections[candidate['election_name']]
        next unless election

        create(
          election_name: candidate['election_name'],
          name: candidate['Candidate'],
          fppc_id: candidate['FPPC#'],
          office_name: candidate['Office'],
          incumbent: candidate['Incumbent']&.downcase == 'true',
        )
      end
    end
  end
end
