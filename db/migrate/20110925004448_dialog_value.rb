class DialogValue < ActiveRecord::Migration
  def self.up
    add_column :dialogs, :max_messages, :integer, :default=>0
    add_column :dialogs, :new_message_title, :string
    add_column :dialogs, :allow_replies, :boolean, :default=>true
    add_column :dialogs, :required_meta, :boolean, :default=>true
    add_column :dialogs, :value_calc, :string, :default=>'total'  
  end

  def self.down
    remove_column :dialogs, :max_messages
    remove_column :dialogs, :new_message_title
    remove_column :dialogs, :allow_replies
    remove_column :dialogs, :required_meta
    remove_column :dialogs, :value_calc  
  end
end
