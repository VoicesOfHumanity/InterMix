class CreateItemThumbs < ActiveRecord::Migration[5.2]
  def change
    create_table :item_thumbs do |t|      
      t.string :original_url
      t.string :our_path
      t.timestamps
    end
    add_index :item_thumbs, [:original_url], length: {original_url: 35}
    add_column :items, :thumb_id, :integer, after: :embed_code
  end
end
