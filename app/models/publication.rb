class Publication < ActiveRecord::Base
  set_primary_key :publication_id
  has_attached_file :avatar

end
