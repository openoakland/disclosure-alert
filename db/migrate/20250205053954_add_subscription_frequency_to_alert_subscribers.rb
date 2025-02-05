class AddSubscriptionFrequencyToAlertSubscribers < ActiveRecord::Migration[7.0]
  def change
    add_column :alert_subscribers, :subscription_frequency, :integer, default: 0
  end
end
