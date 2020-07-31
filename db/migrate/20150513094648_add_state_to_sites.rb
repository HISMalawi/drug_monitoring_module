class AddStateToSites < ActiveRecord::Migration[5.2]
  def change
    change_table :sites do |s|
      s.column :active, :boolean, :default => false
    end
  end
end
