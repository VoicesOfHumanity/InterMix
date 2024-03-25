class CommunityOwner < ActiveRecord::Migration[5.2]
  def change
    add_column :communities, :created_by, :integer
    add_column :communities, :administrator_id, :integer
  end
end
