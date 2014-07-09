class CreateStates < ActiveRecord::Migration
  def change
    create_table :states, :primary_key => :state_id do |t|
      t.integer :observation_id
      t.string :state
      t.timestamps
    end
  end
end
