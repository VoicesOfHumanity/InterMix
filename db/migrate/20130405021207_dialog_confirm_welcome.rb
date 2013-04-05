class DialogConfirmWelcome < ActiveRecord::Migration
  def change
    add_column :dialogs, :confirm_welcome_template, :text, :after => :confirm_email_template
    add_column :dialog_groups, :confirm_welcome_template, :text, :after => :confirm_email_template
    add_column :groups, :confirm_welcome_template, :text, :after => :confirm_email_template
  end
end
