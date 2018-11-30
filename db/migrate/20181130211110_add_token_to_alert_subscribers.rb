class AddTokenToAlertSubscribers < ActiveRecord::Migration[5.2]
  def change
    change_table :alert_subscribers do |t|
      t.string :token
      t.index :token
    end

    AlertSubscriber.reset_column_information

    AlertSubscriber.find_each do |subscriber|
      subscriber.update_attribute(:token, SecureRandom.hex)
    end
  end
end
