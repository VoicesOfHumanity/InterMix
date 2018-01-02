class CommunityFullname < ActiveRecord::Migration
  def change
    change_column :communities, :description, :text
    add_column :communities, :fullname, :string, default: ''
  end
end
