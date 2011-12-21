class DialogMemberTemplate < ActiveRecord::Migration
  def self.up
    add_column :dialogs, :member_template, :text, :after=>:confirm_email_template
    add_column :groups, :member_template, :text, :after=>:front_template
  end

  def self.down
    remove_column :dialogs, :member_template
    remove_column :groups, :member_template
  end
end
