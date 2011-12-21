class ItemAppDecimal < ActiveRecord::Migration
  def self.up
    change_column :items, :interest, :decimal, :precision => 6, :scale => 2, :default => 0.0
    change_column :items, :approval, :decimal, :precision => 6, :scale => 2, :default => 0.0
  end

  def self.down
    change_column :items, :interest, :integer, :default => 0
    change_column :items, :approval, :integer, :default => 0
  end
end
