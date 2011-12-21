class ItemsModby < ActiveRecord::Migration
  def self.up
    change_column :items, :moderated_by, :string
    change_column :items, :item_type, :string, :default=>'message'
  end

  def self.down
  end
end
