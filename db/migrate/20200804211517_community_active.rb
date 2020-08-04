class CommunityActive < ActiveRecord::Migration[5.2]
  def change
    add_column :communities, :active, :boolean, default: :true
  end
end
