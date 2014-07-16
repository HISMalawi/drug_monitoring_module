class AlterObservation < ActiveRecord::Migration
  def up
    change_table :observations do |o|
      o.column :voided, :integer, :default => 0
    end

    change_column :observations, :value_numeric, :decimal
  end

  def down
  end
end
