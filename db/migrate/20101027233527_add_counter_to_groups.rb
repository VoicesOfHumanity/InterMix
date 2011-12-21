class AddCounterToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :group_participants_count, :integer, :default=>0, :after=>:is_network
    add_column :groups, :items_count, :integer, :default=>0, :after=>:group_participants_count
    add_column :participants, :items_count, :integer, :default=>0, :after=>:sysadmin
  end

  def self.down
    remove_column :groups, :group_participants_count
    remove_column :groups, :items_count
    remove_column :participants, :items_count
  end
end
