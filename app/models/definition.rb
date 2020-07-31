class Definition < ActiveRecord::Base
  self.primary_key = "definition_id"
  validates_uniqueness_of :name
end
