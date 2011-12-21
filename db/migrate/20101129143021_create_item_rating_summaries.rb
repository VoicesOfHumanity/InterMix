class CreateItemRatingSummaries < ActiveRecord::Migration
  def self.up
    create_table :item_rating_summaries do |t|
      t.integer :item_id
      t.string :summary_type, :limit => 15
      t.integer :int_0_count, :default => 0
      t.integer :int_1_count, :default => 0
      t.integer :int_2_count, :default => 0
      t.integer :int_3_count, :default => 0
      t.integer :int_4_count, :default => 0
      t.integer :int_count, :default => 0
      t.integer :int_total, :default => 0
      t.integer :int_average, :precision => 6, :scale => 2, :default => 0.0
      t.integer :app_n3_count, :default => 0
      t.integer :app_n2_count, :default => 0
      t.integer :app_n1_count, :default => 0
      t.integer :app_0_count, :default => 0
      t.integer :app_p1_count, :default => 0
      t.integer :app_p2_count, :default => 0
      t.integer :app_p3_count, :default => 0
      t.integer :app_count, :default => 0
      t.integer :app_total, :default => 0
      t.integer :app_average, :precision => 6, :scale => 2, :default => 0.0
      t.decimal :value, :precision => 6, :scale => 2
      t.decimal :controversy, :precision => 6, :scale => 2
      t.timestamps
    end
    add_index :item_rating_summaries, :item_id
    add_index :item_rating_summaries, :int_average
    add_index :item_rating_summaries, :app_average
    add_index :item_rating_summaries, :value
    add_index :item_rating_summaries, :controversy
  end

  def self.down
    drop_table :item_rating_summaries
  end
end
