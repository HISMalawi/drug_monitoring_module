class CreateDrugs < ActiveRecord::Migration[5.2]
  def change
    create_table :drugs, :primary_key => :drug_id do |t|
      t.integer "concept_id", default: 0, null: false
      t.string "name", limit: 50
      t.integer "combination", limit: 2, default: 0, null: false
      t.integer "dosage_form"
      t.float "dose_strength", limit: 53
      t.float "maximum_daily_dose", limit: 53
      t.float "minimum_daily_dose", limit: 53
      t.integer "route"
      t.string "units", limit: 50
      t.integer "creator", default: 0, null: false
      t.integer "retired", limit: 2, default: 0, null: false
      t.integer "retired_by"
      t.datetime "date_retired"
      t.string "retire_reason"
      t.string "uuid", limit: 38, null: false
      t.index ["concept_id"], name: "primary_drug_concept"
      t.index ["creator"], name: "drug_creator"
      t.index ["dosage_form"], name: "dosage_form_concept"
      t.index ["retired_by"], name: "user_who_voided_drug"
      t.index ["route"], name: "route_concept"
      t.index ["uuid"], name: "drug_uuid_index", unique: true
      t.string :full_name, default: "" 
      t.string :short_name, default: ""
      t.integer :category, default: 0 
      t.timestamps
    end
  end
end
