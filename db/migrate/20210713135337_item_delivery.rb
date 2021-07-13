class ItemDelivery < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :wall_delivery, :string, after: :topic, default: 'public'
    add_column :items, :wall_post, :boolean, after: :wall_delivery, default: false
  end
end
