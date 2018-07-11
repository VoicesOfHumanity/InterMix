class CommunityAttachment < ActiveRecord::Migration[4.2]
  def change
    add_attachment :communities, :logo
  end
end
