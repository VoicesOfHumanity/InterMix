class GroupOwner < ActiveRecord::Migration
  def self.up
    add_column :groups, :shortname, :string, :after=>:name
    add_column :groups, :owner, :integer, :after=>:is_network
    add_column :groups, :has_mail_list, :boolean, :default=>true
    add_index :groups, [:shortname], :length => {:shortname=>20}
  end

  def self.down
    remove_column :groups, :shortname
    remove_column :groups, :owner
    remove_column :groups, :has_mail_list
  end
end
