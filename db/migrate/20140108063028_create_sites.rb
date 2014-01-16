class CreateSites < ActiveRecord::Migration
  def change
    create_table :sites, :primary_id => :site_id do |t|
      t.integer :site_id
      t.string :name
      t.string :description
      t.timestamps
    end
  end
end
