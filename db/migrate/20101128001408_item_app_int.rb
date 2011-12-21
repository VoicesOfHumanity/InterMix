class ItemAppInt < ActiveRecord::Migration
  def self.up
    add_column :items, :approval, :integer
    add_column :items, :interest, :integer
    add_column :items, :value, :decimal, :precision => 6, :scale => 2
    add_column :items, :controversy, :decimal, :precision => 6, :scale => 2
  end

  def self.down
    remove_column :items, :approval
    remove_column :items, :interest
    remove_column :items, :value
    remove_column :items, :controversy
  end
end
