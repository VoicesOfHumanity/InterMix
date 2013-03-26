class ShortDescriptions < ActiveRecord::Migration
  def change
    add_column :groups, :shortdesc, :text, :after=>:description
    add_column :dialogs, :shortdesc, :text, :after=>:description
    add_column :periods, :shortdesc, :text, :after=>:description
  end
end
