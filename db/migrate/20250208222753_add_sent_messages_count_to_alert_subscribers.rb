class AddSentMessagesCountToAlertSubscribers < ActiveRecord::Migration[7.0]
  def change
    change_table :alert_subscribers do |t|
      t.integer :sent_messages_count, default: 0, null: false
    end

    reversible do |dir|
      dir.up do
        AlertSubscriber.find_each do |subscriber|
          AlertSubscriber.reset_counters(subscriber.id, :sent_messages_count)
        end
      end
    end
  end
end
