class AddContentXmlToFilings < ActiveRecord::Migration[5.2]
  def change
    change_table :filings do |t|
      t.xml :contents_xml
    end
  end
end
