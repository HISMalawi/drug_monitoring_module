class State < ActiveRecord::Base
  # attr_accessible :title, :body
  set_primary_key :state_id
  belongs_to :observation, :foreign_key => :observation_id
  validates_presence_of :observation_id

end
