class Drug < ActiveRecord::Base
  # attr_accessible :title, :body
  set_primary_key :drug_id
  belongs_to :definition, :foreign_key => :category_id
  validates_uniqueness_of :full_name

  def self.check(name)
    drug_id = Drug.where("full_name = ? OR short_name = ?", "#{name}", "#{name}").first.id rescue create_drug(name)
    return drug_id
  end

  def self.create_drug(name, short_name = name, category = 'unknown')

    category_id = Definition.find_by_name(category).id rescue Definition.find_by_name("unknown").id
    drug = Drug.where(:full_name => name, :short_name => short_name, :category => category_id).first_or_create
    return drug.id
  end
end
