class ItemPerspective < ActiveRecord::Migration
  def change
    add_column :items, :geo_level, :string
    add_index :items, [:geo_level,:id], :length => {:geo_level=>10}
  end
end
