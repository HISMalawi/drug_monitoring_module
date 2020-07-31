class CreateSites < ActiveRecord::Migration[5.2]
  def change
    create_table :sites, :primary_key => :site_id do |t|
      t.string :name
      t.string :description
      t.timestamps
    end
  end
end
