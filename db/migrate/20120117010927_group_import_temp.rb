class GroupImportTemp < ActiveRecord::Migration
  def change
    add_column :groups, :invite_template, :text, :after=>:member_template
    add_column :groups, :import_template, :text, :after=>:invite_template
  end
end
