class PullTracker < ActiveRecord::Base
  # attr_accessible :title, :body
  self.primary_key = "pull_tracker_id"
  belongs_to :site, :foreign_key => :site_id
end
