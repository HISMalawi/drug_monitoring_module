class DrugSet < ActiveRecord::Base
  set_table_name :drug_set
  set_primary_key :drug_set_id
  belongs_to :definition
  belongs_to :drug, :foreign_key => :drug_id
  validates_presence_of :drug_id

  def get_short_name
    self.drug.short_name
  end
end
