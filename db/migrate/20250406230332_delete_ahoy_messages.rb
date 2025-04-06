class DeleteAhoyMessages < ActiveRecord::Migration[7.2]
  def change
    drop_table :ahoy_messages
  end
end
