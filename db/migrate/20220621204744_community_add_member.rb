class CommunityAddMember < ActiveRecord::Migration[5.2]
  def change
    add_column :communities, :who_add_members, :string, default: 'admin'   # member, moderator, admin, super
  end
end
