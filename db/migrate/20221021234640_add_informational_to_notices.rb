class AddInformationalToNotices < ActiveRecord::Migration[7.0]
  def change
    add_column :notices, :informational, :boolean
  end
end
