# frozen_string_literal: true

class CreateFilings < ActiveRecord::Migration[5.2]
  create_table :filings do |t|
    t.string :filer_id
    t.string :filer_name
    t.string :title
    t.string :amendment_sequence_number
    t.string :amended_filing_id
    t.string :form
    t.datetime :filed_at

    t.json :contents
  end
end
