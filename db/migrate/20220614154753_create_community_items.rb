class CreateCommunityItems < ActiveRecord::Migration[5.2]
  def change
    create_table :community_items do |t|
      t.integer :community_id
      t.integer :item_id
      t.timestamps
    end
    add_index :community_items, [:community_id, :item_id]
    add_index :community_items, [:item_id, :community_id]
  end
end
