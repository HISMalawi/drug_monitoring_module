class DrugCms < ActiveRecord::Base
  set_primary_key :drug_inventory_id


  def get_category
    Definition.find_by_definition_id(self.category).name
  end
end
