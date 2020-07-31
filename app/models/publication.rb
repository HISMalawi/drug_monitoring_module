class Publication < ActiveRecord::Base
  self.primary_key = "publication_id"
  has_attached_file :avatar

end
