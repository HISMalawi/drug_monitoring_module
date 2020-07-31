class CreateDrugs < ActiveRecord::Migration[5.2]
  def change
    create_table :drugs, :primary_key => :drug_id do |t|
      t.string :full_name
      t.string :short_name
      t.integer :category
      t.integer :voided, :default => 0
      t.timestamps
    end
  end
end
