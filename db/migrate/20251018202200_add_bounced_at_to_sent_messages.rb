class AddBouncedAtToSentMessages < ActiveRecord::Migration[7.2]
  def change
    add_column :sent_messages, :bounced_at, :datetime
  end
end
