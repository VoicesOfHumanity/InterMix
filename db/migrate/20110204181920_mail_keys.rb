class MailKeys < ActiveRecord::Migration
  def self.up
    add_column :participants, :direct_email_code, :string
    add_index :participants, [:direct_email_code], :length => {:direct_email_code=>20}
    add_column :group_participants, :direct_email_code, :string, :after=>:active
    add_index :group_participants, [:direct_email_code], :length => {:direct_email_code=>20}
    add_column :items, :posted_via, :string, :default=>'web'
  end

  def self.down
    remove_column :participants, :direct_email_code
    remove_column :group_participants, :direct_email_code
    remove_column :items, :posted_via
  end
end
