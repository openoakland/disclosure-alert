class CreateElectionCommittee < ActiveRecord::Migration[5.2]
  def change
    create_table :election_committees do |t|
      t.string :name
      t.string :fppc_id
      t.string :candidate_controlled_id
      t.string :support_or_oppose
      t.string :ballot_measure
      t.string :ballot_measure_election
    end
  end
end
