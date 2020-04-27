namespace :disclosure_alert do
  desc 'Sync Election, ElectionCandidate, etc. from Open Disclosure Candidates CSV'
  task election_csv_sync: :environment do
    Election.replace_all_from_csv
    ElectionCandidate.replace_all_from_csv
    ElectionReferendum.replace_all_from_csv
    ElectionCommittee.replace_all_from_csv
  end
end
