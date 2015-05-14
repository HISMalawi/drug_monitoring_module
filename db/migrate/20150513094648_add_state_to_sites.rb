class AddStateToSites < ActiveRecord::Migration
  def change
    change_table :sites do |s|
      s.column :active, :boolean, :default => false
    end
  end
end
