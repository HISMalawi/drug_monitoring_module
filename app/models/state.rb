class State < ActiveRecord::Base
  # attr_accessible :title, :body
  set_primary_key :state_id
  belongs_to :observation, :foreign_key => :observation_id
  belongs_to :definition, :foreign_key => :state
  validates_presence_of :observation_id

  def state_name
    self.definition.name
  end
end
