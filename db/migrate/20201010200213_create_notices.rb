class CreateNotices < ActiveRecord::Migration[5.2]
  def change
    create_table :notices do |t|
      t.date :date
      t.text :body
      t.references :creator, index: true, foreign_key: { to_table: :admin_users }

      t.timestamps
    end
  end
end
