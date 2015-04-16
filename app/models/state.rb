class State < ActiveRecord::Base
  # attr_accessible :title, :body
  set_primary_key :state_id
  belongs_to :observation, :foreign_key => :observation_id
  belongs_to :definition, :foreign_key => :state
  validates_presence_of :observation_id

  def state_name
    self.definition.name
  end

  def comments
    comments = Observation.where("definition_id = ? AND value_numeric = ?",
                                 Definition.find_by_name("comment").id, self.id)

    html = "'"
    (comments || []).each do |comment|
      html += "#{comment.value_text} -#{comment.creator_name}<br/>"
    end
    html += "'"
    return html.html_safe
  end

  def notice
    return Observation.where("observation_id = ? ", self.observation_id).first.value_text
  end

  def last_person_to_update
    last_editor = Observation.where("definition_id = ? AND value_numeric = ?",
                                    Definition.find_by_name("comment").id, self.id).order("created_at ASC").last.creator_name
  end
end
