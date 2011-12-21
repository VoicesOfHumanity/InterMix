class RatingDecimal < ActiveRecord::Migration
  def self.up
    change_column :item_rating_summaries, :int_average, :decimal, :precision => 6, :scale => 2, :default => 0.0
    change_column :item_rating_summaries, :app_average, :decimal, :precision => 6, :scale => 2, :default => 0.0
  end

  def self.down
    change_column :item_rating_summaries, :int_average, :integer, :default => 0
    change_column :item_rating_summaries, :app_average, :integer, :default => 0
  end
end
