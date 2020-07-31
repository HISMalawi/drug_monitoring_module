class CreateDrugSets < ActiveRecord::Migration[5.2]
  def change
    create_table :drug_set,:primary_key => :drug_set_id do |t|

      t.integer :definition_id
      t.integer :drug_id
      t.integer :weight
      t.boolean :voided , :default => false
      t.timestamps
    end
  end
end
