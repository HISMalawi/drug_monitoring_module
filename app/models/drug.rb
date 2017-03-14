require 'couchrest_model'
class Drug < CouchRest::Model::Base
  property :full_name, String
  property :short_name, String
  property :category, String
  property :voided, TrueClass, :default => false

  design do
    view :by_full_name
    view :by_short_name
    view :by_category
  end

  def self.check(name)
    drug_id = Drug.where("full_name = ? OR short_name = ?", "#{name}", "#{name}").first.id rescue create_drug(name)
    return drug_id
  end

  def self.create_drug(name, short_name = name, category = 'unknown')

    category_id = Definition.find_by_name(category).id rescue Definition.find_by_name("unknown").id
    drug = Drug.where(:full_name => name, :short_name => short_name, :category => category_id).first_or_create
    return drug.id
  end

  def get_category
    Definition.find_by_definition_id(self.category).name
  end
end
