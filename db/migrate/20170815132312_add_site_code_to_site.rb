class AddSiteCodeToSite < ActiveRecord::Migration[5.2]
  def change
    add_column :sites, :site_code, :string
  end
end
