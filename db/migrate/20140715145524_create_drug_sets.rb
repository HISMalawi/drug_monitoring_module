class CreateDrugSets < ActiveRecord::Migration
  def change
    create_table :drug_set,:primary_key => :drug_set_id do |t|

      t.integer :definition_id
      t.string :drug_name
      t.integer :weight
      t.boolean :voided , :default => false
      t.timestamps
    end
  end
end
