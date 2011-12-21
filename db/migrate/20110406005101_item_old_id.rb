class ItemOldId < ActiveRecord::Migration
  def self.up
    add_column :items, :old_message_id, :integer
    add_index :items, [:old_message_id]
  end

  def self.down
    remove_column :items, :old_message_id
  end
end
