class DialogStartStop < ActiveRecord::Migration
  def self.up
    add_column :dialogs, :posting_open, :boolean, :default => true
    add_column :dialogs, :voting_open, :boolean, :default => true
  end

  def self.down
    remove_column :dialogs, :posting_open
    remove_column :dialogs, :voting_open
  end
end
