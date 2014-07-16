class DrugSet < ActiveRecord::Base
  set_table_name :drug_set
  set_primary_key :drug_set_id
  belongs_to :definition
end
