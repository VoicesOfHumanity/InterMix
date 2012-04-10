class DialogGroupsTemplates < ActiveRecord::Migration
  def change
    add_column :dialog_groups, :signup_template, :text
    add_column :dialog_groups, :confirm_template, :text
    add_column :dialog_groups, :confirm_email_template, :text
  end
end
