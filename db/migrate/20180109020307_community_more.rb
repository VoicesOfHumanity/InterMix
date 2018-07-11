class CommunityMore < ActiveRecord::Migration[4.2]
  def change
    add_column :communities, :more, :boolean, default: false, after: :major
  end
end
