class AddElectionCandidate < ActiveRecord::Migration[5.2]
  def change
    create_table :election_candidates do |t|
      t.string :election_name, null: false
      t.string :name, null: false
      t.string :fppc_id
      t.string :office_name
      t.boolean :incumbent
    end
  end
end
