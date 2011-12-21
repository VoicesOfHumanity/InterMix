class DialogFrontTemplate < ActiveRecord::Migration
  def self.up
    add_column :dialogs, :front_template, :text, :after=>:signup_template
    add_column :groups, :front_template, :text
  end

  def self.down
    remove_column :dialogs, :front_template
    remove_column :groups, :front_template
  end
end
