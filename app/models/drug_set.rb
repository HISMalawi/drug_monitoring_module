class DrugSet < ActiveRecord::Base
  set_table_name :drug_set
  set_primary_key :drug_set_id
  belongs_to :definition
  belongs_to :drug, :foreign_key => :drug_id
  belongs_to :drug_cms, :foreign_key => :drug_id
  validates_presence_of :drug_id

  def get_short_name
    "#{self.drug_cms.short_name} #{self.drug_cms.strength} #{self.drug_cms.tabs}"
  end
end
