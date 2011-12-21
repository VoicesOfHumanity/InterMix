class CreateHubs < ActiveRecord::Migration
  def self.up
    create_table :hubs do |t|
      t.string :name
      t.timestamps
    end
    add_index :hubs, :name
  end

  def self.down
    drop_table :hubs
  end
end
