class ItemIndexes < ActiveRecord::Migration[5.2]
  def change
    safe_add_index :ratings, [:conversation_id, :participant_id]
    safe_add_index :ratings, [:item_id, :participant_id, :created_at]
    safe_add_index :items, [:conversation_id, :created_at, :censored]
    # MyISAM + utf8mb4: prefix geo_level (varchar 255) to fit 1000-byte key limit
    safe_add_index :items, [:geo_level, :conversation_id, :created_at], length: { geo_level: 10 }
    # MyISAM + utf8mb4: prefix city (varchar 255)
    safe_add_index :participants, [:country_code, :admin1uniq, :city], length: { city: 100 }
    safe_add_index :items, [:intra_com, :created_at, :censored], length: { intra_com: 30 }
    safe_add_index :items, [:intra_conv, :created_at, :censored], length: { intra_conv: 30 }
    safe_add_index :items, [:posted_by, :created_at, :censored]
    safe_add_index :items, [:wall_post, :wall_delivery, :created_at], length: { wall_delivery: 30 }
    safe_add_index :participants, [:admin2uniq, :metro_area_id]
    safe_add_index :participants, [:city, :admin1uniq], length: { city: 100 }
    safe_add_index :ratings, [:item_id, :created_at]
    safe_add_index :ratings, [:participant_id, :created_at]
    safe_add_index :complaints, [:complainer_id, :item_id]
    safe_add_index :follows, [:following_id, :followed_remote_actor_id]
  end

  private

  def safe_add_index(table, columns, options = {})
    return if index_exists?(table, columns)
    add_index(table, columns, options)
  end
end
