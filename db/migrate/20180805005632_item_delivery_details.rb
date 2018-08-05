class ItemDeliveryDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :item_deliveries, :item_id, :integer, before: :created_at
    add_column :item_deliveries, :participant_id, :integer, before: :created_at
    add_column :item_deliveries, :context, :string, before: :created_at
    add_column :item_deliveries, :sent_at, :datetime, before: :created_at
    add_column :item_deliveries, :seen_at, :datetime, before: :created_at
    add_index :item_deliveries, [:item_id,:participant_id]
    add_index :item_deliveries, [:participant_id,:item_id]
  end
end
