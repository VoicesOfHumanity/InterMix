class GroupsVisibility < ActiveRecord::Migration
  def self.up
    add_column :groups, :visibility, :string, :after=>:description, :default=>'public'
    add_column :participants, :visibility, :string, :default=>'visible_to_all'
  end

  def self.down
    remove_column :groups, :visibility
    remove_column :participants, :visibility
  end
end
