class ItemIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :ratings, [:conversation_id, :participant_id]
    add_index :ratings, [:item_id, :participant_id, :created_at]
    add_index :items, [:conversation_id, :created_at, :censored]
    add_index :items, [:geo_level, :conversation_id, :created_at]
    add_index :participants, [:country_code, :admin1uniq, :city]
    add_index :items, [:intra_com, :created_at, :censored]
    add_index :items, [:intra_conv, :created_at, :censored]
    add_index :items, [:posted_by, :created_at, :censored]
    add_index :items, [:wall_post, :wall_delivery, :created_at]
    add_index :participants, [:admin2uniq, :metro_area_id]
    add_index :participants, [:city, :admin1uniq]
    add_index :ratings, [:item_id, :created_at]
    add_index :ratings, [:participant_id, :created_at]
    add_index :complaints, [:complainer_id, :item_id]
    add_index :follows, [:following_id, :followed_remote_actor_id]
  end
end
