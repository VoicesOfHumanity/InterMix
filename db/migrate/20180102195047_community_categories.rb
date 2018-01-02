class CommunityCategories < ActiveRecord::Migration
  def change
    add_column :communities, :major, :boolean, default: false
    add_column :communities, :ungoals, :boolean, default: false
    add_column :communities, :sustdev, :boolean, default: false
    add_column :communities, :bold, :boolean, default: false
  end
end
