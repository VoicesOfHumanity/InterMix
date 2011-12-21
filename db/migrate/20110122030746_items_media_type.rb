class ItemsMediaType < ActiveRecord::Migration
  def self.up
    add_column :items, :media_type, :string, :after=>:item_type, :default=>'text'
    add_column :items, :link, :string, :after=>:xml_content
  end

  def self.down
    remove_column :items, :media_type
    remove_column :items, :link
  end
end
