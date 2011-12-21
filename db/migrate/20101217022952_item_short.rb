class ItemShort < ActiveRecord::Migration
  def self.up
    add_column :items, :short_content, :text, :after=>:moderated_by
  end

  def self.down
    remove_column :items, :short_content
  end
end
