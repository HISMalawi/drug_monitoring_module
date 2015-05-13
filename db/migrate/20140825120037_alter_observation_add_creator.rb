class AlterObservationAddCreator < ActiveRecord::Migration
  def up
    change_table :observations do |o|
      o.column :creator, :integer, :default => 1
    end
  end

  def down
  end
end
