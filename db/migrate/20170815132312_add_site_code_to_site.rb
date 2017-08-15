class AddSiteCodeToSite < ActiveRecord::Migration
  def change
    add_column :sites, :site_code, :string
  end
end
