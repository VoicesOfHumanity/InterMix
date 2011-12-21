class DialogConfTemp < ActiveRecord::Migration
  def self.up
    add_column :dialogs, :confirm_template, :text, :after=>:front_template
    add_column :dialogs, :confirm_email_template, :text, :after=>:confirm_template
    add_column :dialogs, :required_message, :boolean, :default=>true
    add_column :dialogs, :alt_logins, :boolean, :default=>true
    add_column :groups, :alt_logins, :boolean, :default=>true
  end

  def self.down
    remove_column :dialogs, :confirm_template
    remove_column :dialogs, :confirm_email_template
    remove_column :dialogs, :required_message
    remove_column :dialogs, :alt_logins
    remove_column :groups, :alt_logins
  end
end
