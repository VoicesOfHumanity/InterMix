class ItemsMediaType2 < ActiveRecord::Migration
  def self.up
    add_column :items, :oembed_response, :text
    add_column :items, :embed_code, :text
    add_column :items, :has_picture, :boolean, :default => false
  end

  def self.down
    remove_column :items, :oembed_response
    remove_column :items, :embed_code
    remove_column :items, :has_picture
  end
end
