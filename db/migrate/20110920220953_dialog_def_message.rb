class DialogDefMessage < ActiveRecord::Migration
  def self.up
    add_column :dialogs, :default_message, :text
  end

  def self.down
    remove_column :dialogs, :default_message
  end
end
