class CreateHubAdmins < ActiveRecord::Migration
  def self.up
    create_table :hub_admins do |t|
      t.integer :hub_id
      t.integer :participant_id
      t.boolean :active, :default => true
      t.timestamps
    end
    add_index :hub_admins, [:hub_id,:participant_id]
  end

  def self.down
    drop_table :hub_admins
  end
end
