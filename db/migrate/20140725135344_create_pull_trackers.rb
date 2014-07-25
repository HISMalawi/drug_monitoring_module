class CreatePullTrackers < ActiveRecord::Migration
  def change
    create_table :pull_trackers, :primary_key => :pull_tracker_id do |t|
      t.integer :site_id, :null => false
      t.datetime :pulled_datetime, :null => true

      t.timestamps
    end
  end

  def self.down
    drop_table :pull_trackers
  end
end
