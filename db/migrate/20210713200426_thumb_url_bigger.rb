class ThumbUrlBigger < ActiveRecord::Migration[5.2]
  def change
    change_column :item_thumbs, :original_url, :text
  end
end
