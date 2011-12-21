class FacebookLogin < ActiveRecord::Migration
  def self.up
    add_column :participants, :fb_uid, :string
    add_column :participants, :fb_link, :string
  end

  def self.down
    remove_column :participants, :fb_uid
    remove_column :participants, :fb_link
  end
end
