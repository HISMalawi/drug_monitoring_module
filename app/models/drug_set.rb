require 'couchrest_model'
class DrugSet < CouchRest::Model::Base
  #belongs_to :drug, :foreign_key => :drug_id
  #belongs_to :drug_cms, :foreign_key => :drug_id

  property :definition_id, Integer
  property :drug_id, Integer
  property :weight, Integer
  property :voided, TrueClass, :default => false

  design do
    view :by_drug_id
  end

  def get_short_name
    #"#{self.drug_cms.short_name} #{self.drug_cms.strength} #{self.drug_cms.tabs}"
  end
end
