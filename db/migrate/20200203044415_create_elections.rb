# frozen_string_literal: true

class CreateElections < ActiveRecord::Migration[5.2]
  def change
    create_table :elections do |t|
      t.string :slug, null: false
      t.string :location, null: false
      t.date :date, null: false
      t.string :title, null: false

      t.date :deadline_semi_annual_pre_pre
      t.date :deadline_semi_annual_pre
      t.date :deadline_1st_pre_election
      t.date :deadline_2nd_pre_election
      t.date :deadline_semi_annual_post
    end
  end
end
