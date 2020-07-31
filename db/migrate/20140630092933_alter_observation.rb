class AlterObservation < ActiveRecord::Migration[5.2]
  def up
    change_table :observations do |o|
      o.column :voided, :integer, :default => 0
    end

    change_column :observations, :value_numeric, :double
  end

  def down
  end
end
