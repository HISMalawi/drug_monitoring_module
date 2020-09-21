class CreateDrugMaps < ActiveRecord::Migration[5.2]
  def change
    create_table :drug_maps, :primary_key => :drug_map_id do |t|

      t.string :name
      t.string :short_name
    end
  end
end
