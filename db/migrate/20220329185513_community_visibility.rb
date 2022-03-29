class CommunityVisibility < ActiveRecord::Migration[5.2]
  def change
    add_column :communities, :visibility, :string, default: "public"
    add_column :communities, :message_visibility, :string, default: "public"
  end
end
