class CreateDrugCms < ActiveRecord::Migration[5.2]
  def self.up
    create_table :drug_cms, :id => false do |t|
      t.integer :drug_inventory_id, :null => false
      t.string :name, :null => false
      t.string :code
      t.string :short_name, :limit => 225
      t.string :tabs, :limit => 225
      t.integer :pack_size
      t.integer :weight
      t.string :strength
      t.integer :category
      t.integer :voided, :default => 0, :limit => 1
      t.integer :voided_by , :limit => 5
      t.datetime :date_voided
      t.string :void_reason, :limit => 225
      t.timestamps
    end
    execute "ALTER TABLE drug_cms ADD PRIMARY KEY (drug_inventory_id)"
  end

  def self.down
    drop_table :drug_cms
  end

end
