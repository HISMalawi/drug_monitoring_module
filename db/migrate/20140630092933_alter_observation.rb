class AlterObservation < ActiveRecord::Migration
  def up
    change_table :observations do |o|
      o.column :voided, :integer, :default => 0
    end
  end

  def down
  end
end
