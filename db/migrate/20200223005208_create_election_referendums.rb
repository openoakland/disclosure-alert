class CreateElectionReferendums < ActiveRecord::Migration[5.2]
  def change
    create_table :election_referendums do |t|
      t.string :election_name, null: false
      t.string :measure_number
      t.string :title
      t.string :full_title

      t.timestamps
    end
  end
end
