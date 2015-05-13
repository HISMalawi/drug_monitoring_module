class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles, :primary_key => :role_id do |t|

      t.string :role
      t.string :description
    end
  end

  def self.down
    drop_table :roles
  end
end
