class EmailSetting < ActiveRecord::Migration
  def self.up
    add_column :participants, :forum_email, :string, :default=>'never'
    add_column :participants, :group_email, :string, :default=>'instant'
    add_column :participants, :private_email, :string, :default=>'instant'
    add_column :participants, :system_email, :string, :default=>'instant'
  end

  def self.down
    remove_column :participants, :forum_email
    remove_column :participants, :group_email
    remove_column :participants, :private_email
    remove_column :participants, :system_email
  end
end
