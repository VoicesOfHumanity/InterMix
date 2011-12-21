class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.string :name
      t.text :description
      t.string :openness
      t.boolean :moderation, :default=>false
      t.boolean :is_network, :default=>false
      t.timestamps
    end
    add_index :groups, :name
  end

  def self.down
    drop_table :groups
  end
end
