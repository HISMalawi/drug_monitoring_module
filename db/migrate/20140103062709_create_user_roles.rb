class CreateUserRoles < ActiveRecord::Migration
  def self.up
    create_table :user_roles, :primary_key => :user_role_id do |t|

      t.integer :user_id
      t.integer :role_id
    end
  end

  def self.down
    drop_table :user_roles
  end
end
