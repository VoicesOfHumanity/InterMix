class CommunityAutotags < ActiveRecord::Migration[5.1]
  def change
    add_column :communities, :autotags, :text
  end
end
