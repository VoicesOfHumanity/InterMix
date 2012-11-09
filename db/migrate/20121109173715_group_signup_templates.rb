class GroupSignupTemplates < ActiveRecord::Migration
  def change
    add_column :groups, :signup_template, :text, :after => :import_template
    add_column :groups, :confirm_template, :text, :after => :signup_template
    add_column :groups, :confirm_email_template, :text, :after => :confirm_template  
  end
end
