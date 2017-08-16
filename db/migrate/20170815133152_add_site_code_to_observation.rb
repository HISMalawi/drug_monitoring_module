class AddSiteCodeToObservation < ActiveRecord::Migration
  def change
    add_column :observations, :site_code, :string
  end
end
