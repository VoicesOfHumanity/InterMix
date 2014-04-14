class ItemCensor < ActiveRecord::Migration
  def change
    add_column :items, :censored, :boolean, :default => false
  end
end
