class CreateDefinitions < ActiveRecord::Migration[5.2]
  def change
    create_table :definitions, :primary_key => :definition_id do |t|
      t.string :name
      t.string :description
      t.timestamps
    end
  end
end
