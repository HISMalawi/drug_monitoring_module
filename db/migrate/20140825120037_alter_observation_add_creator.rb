class AlterObservationAddCreator < ActiveRecord::Migration[5.2]
  def up
    change_table :observations do |o|
      o.column :creator, :integer, :default => 1
    end
  end

  def down
  end
end
