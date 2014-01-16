class CreateObservations < ActiveRecord::Migration
  def change
    create_table :observations, :primary_key => :observation_id do |t|
      t.integer :site_id
      t.integer :definition_id
      t.integer :value_numeric
      t.date :value_date
      t.string  :value_text
      t.string :value_drug
      t.timestamps
    end
  end
end
