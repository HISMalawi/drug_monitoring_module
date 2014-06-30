class AlterSites < ActiveRecord::Migration
  def up
    change_table :sites do |s|
      s.column :x, :string, :default => " "
      s.column :y, :string, :default => " "
      s.column :ip_address, :string, :default => " "
      s.column :port, :string, :default => " "
      s.column :region, :string, :default => " "
    end
  end

  def down

  end
end
