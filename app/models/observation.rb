class Observation < ActiveRecord::Base
  set_primary_key :observation_id
  belongs_to :site, :foreign_key => :site_id
  belongs_to :definition, :foreign_key => :definition_id
  validates_presence_of :site_id
  validates_presence_of :definition_id
end
