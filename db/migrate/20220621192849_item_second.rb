class ItemSecond < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :community_id, :integer, after: :conversation_id
    add_column :items, :community2_id, :integer, after: :community_id
  end
end
