class CreateFilingDeadlines < ActiveRecord::Migration[7.0]
  def change
    create_table :filing_deadlines do |t|
      t.date :date
      t.date :report_period_begin
      t.date :report_period_end
      t.integer :deadline_type
      t.integer :netfile_agency_id

      t.timestamps
    end
  end
end
