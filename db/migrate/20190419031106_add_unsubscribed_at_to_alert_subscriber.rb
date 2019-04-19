class AddUnsubscribedAtToAlertSubscriber < ActiveRecord::Migration[5.2]
  def change
    change_table :alert_subscribers do |t|
      t.datetime :unsubscribed_at
    end
  end
end
