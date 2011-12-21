class ItemReply < ActiveRecord::Migration
  def self.up
    add_column :items, :reply_to, :integer
    add_column :items, :is_first_in_thread, :boolean
    add_column :items, :first_in_thread, :integer
    add_index :items, [:first_in_thread, :id]
  end

  def self.down
    remove_column :items, :reply_to
    remove_column :items, :is_first_in_thread
    remove_column :items, :first_in_thread
  end
end
