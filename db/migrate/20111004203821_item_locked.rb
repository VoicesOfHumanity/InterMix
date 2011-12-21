class ItemLocked < ActiveRecord::Migration
  def self.up
    add_column :items, :edit_locked, :boolean, :default => false
    add_column :dialogs, :required_subject, :boolean, :default => true, :after => :required_message
    add_column :dialogs, :profiles_visible, :boolean, :default => true
  end

  def self.down
    remove_column :items, :edit_locked
    remove_column :dialogs, :required_subject
    remove_column :dialogs, :profiles_visible
  end
end
