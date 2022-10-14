class AddAgencyIdToFilings < ActiveRecord::Migration[7.0]
  def up
    create_table :netfile_agencies do |t|
      t.integer :netfile_id
      t.string :shortcut
      t.string :name

      t.index :netfile_id, unique: true
      t.index :shortcut, unique: true
    end

    oakland = NetfileAgency.create(netfile_id: 13, shortcut: 'COAK', name: 'Oakland, City of')
    _sf = NetfileAgency.create(netfile_id: 52, shortcut: 'SFO', name: 'San Francisco Ethics Commission')

    change_table :filings do |t|
      t.references :netfile_agency, default: oakland.id
    end

    change_table :alert_subscribers do |t|
      t.references :netfile_agency, default: oakland.id
    end
  end

  def down
    remove_reference :netfile_filings, :agency
    remove_reference :netfile_alert_subscribers, :agency
    drop_table :netfile_agencies
  end
end
