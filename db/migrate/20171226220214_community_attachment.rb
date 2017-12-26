class CommunityAttachment < ActiveRecord::Migration
  def change
    add_attachment :communities, :logo
  end
end
