class CreateDrugMaps < ActiveRecord::Migration
  def change
    create_table :drug_maps, :primary_key => :drug_map_id do |t|

      t.string :full_name
      t.string :short_name
    end
  end
end
