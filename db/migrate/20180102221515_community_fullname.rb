class CommunityFullname < ActiveRecord::Migration[4.2]
  def change
    change_column :communities, :description, :text
    add_column :communities, :fullname, :string, default: ''
  end
end
