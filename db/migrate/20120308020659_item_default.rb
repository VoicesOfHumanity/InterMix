class ItemDefault < ActiveRecord::Migration
  def change
    change_column :items, :value, :decimal, :precision => 6, :scale => 2, :default => 0.0
    change_column :items, :controversy, :decimal, :precision => 6, :scale => 2, :default => 0.0
  end
end
