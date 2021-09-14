class CommunityTwocountry < ActiveRecord::Migration[5.2]
  def change
    add_column :communities, :conversation_id, :integer
  end
end
