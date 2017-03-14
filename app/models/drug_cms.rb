require 'couchrest_model'
class DrugCms < CouchRest::Model::Base
  #set_primary_key :drug_inventory_id

  property :drug_inventory_id, Integer
  property :name, String
  property :short_name, String
  property :tabs, Integer
  property :code, String
  property :pack_size, Integer
  property :weight, Integer
  property :strength, String
  property :category, String

  design do
    view :by_drug_inventory_id
    view :by_short_name
    view :by_name
  end
  
  def get_category
    #Definition.find_by_definition_id(self.category).name
    Definition.find(self.category).name
  end
  
end
