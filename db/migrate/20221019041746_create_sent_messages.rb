class CreateSentMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :sent_messages do |t|
      t.references :alert_subscriber, null: false, foreign_key: true
      t.string :message_id
      t.string :mailer
      t.string :subject
      t.datetime :sent_at
      t.datetime :opened_at
      t.datetime :clicked_at

      t.index :message_id, unique: true
    end
  end
end
