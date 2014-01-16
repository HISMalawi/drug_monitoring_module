class CreateDefinitions < ActiveRecord::Migration
  def change
    create_table :definitions, :primary_key => :definition_id do |t|
      t.string :name
      t.string :description
      t.timestamps
    end
  end
end
