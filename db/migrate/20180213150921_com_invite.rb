class ComInvite < ActiveRecord::Migration[5.1]
  def change
    add_column :communities, :front_template, :text
    add_column :communities, :member_template, :text
    add_column :communities, :invite_template, :text
    add_column :communities, :import_template, :text
    add_column :communities, :signup_template, :text
    add_column :communities, :confirm_template, :text
    add_column :communities, :confirm_email_template, :text
    add_column :communities, :confirm_welcome_template, :text
  end
end
