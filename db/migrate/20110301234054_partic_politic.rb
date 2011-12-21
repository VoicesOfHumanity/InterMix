class ParticPolitic < ActiveRecord::Migration
  def self.up
    add_column :participants, :political, :string, :after=>:faith_tradition
    add_column :participants, :wall_visibility, :string, :default=>'all', :after=>:visibility
    add_column :participants, :item_to_forum, :boolean, :default=>true, :after=>:wall_visibility
    add_column :participants, :has_participated, :boolean, :default=>false
    add_column :items, :posted_to_forum, :boolean, :default=>true, :after=>:promoted_to_forum  
  end

  def self.down
    remove_column :participants, :political
    remove_column :participants, :wall_visibility
    remove_column :participants, :item_to_forum
    remove_column :participants, :has_participated
    remove_column :items, :posted_to_forum    
  end
end
