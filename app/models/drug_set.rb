class DrugSet < ActiveRecord::Base
  set_table_name :drug_set
  set_primary_key :drug_set_id
  belongs_to :definition

  def get_short_name
    DrugMap.where(:full_name => self.drug_name).first.short_name rescue self.drug_name
  end
end
