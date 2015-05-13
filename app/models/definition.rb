class Definition < ActiveRecord::Base
  set_primary_key :definition_id
  validates_uniqueness_of :name
end
