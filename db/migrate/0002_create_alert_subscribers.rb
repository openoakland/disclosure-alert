# frozen_string_literal: true

# Alert subscribers are people that will receive the email.
class CreateAlertSubscribers < ActiveRecord::Migration[5.2]
  create_table :alert_subscribers do |t|
    t.string :email, null: false

    t.timestamps
  end
end
