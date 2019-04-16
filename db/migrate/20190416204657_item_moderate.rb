class ItemModerate < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :been_moderated, :boolean, default: true, after: :tweeted_group_at
    add_column :communities, :moderated, :boolean, default: false
  end
end
