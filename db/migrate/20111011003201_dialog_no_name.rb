class DialogNoName < ActiveRecord::Migration
  def self.up
    add_column :dialogs, :names_visible_voting, :boolean, :default => true
    add_column :dialogs, :names_visible_general, :boolean, :default => true
    add_column :participants, :handle, :string
  end

  def self.down
    remove_column :dialogs, :names_visible_voting
    remove_column :dialogs, :names_visible_general
    remove_column :participants, :handle
  end
end
