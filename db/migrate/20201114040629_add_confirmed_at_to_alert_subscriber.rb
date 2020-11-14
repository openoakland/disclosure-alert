# frozen_string_literal: true

class AddConfirmedAtToAlertSubscriber < ActiveRecord::Migration[5.2]
  SPAM_START_DATE = Date.new(2020, 11, 7)

  def change
    change_table :alert_subscribers do |t|
      t.datetime :confirmed_at
    end

    AlertSubscriber.where('created_at < ?', SPAM_START_DATE).update_all(confirmed_at: Time.now)
  end
end
