class CommunityMore < ActiveRecord::Migration
  def change
    add_column :communities, :more, :boolean, default: false, after: :major
  end
end
