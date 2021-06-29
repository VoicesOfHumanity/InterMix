class ItemRemoteDelivery < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :remote_delivery_done, :boolean, default: :true
    add_index :items, [:remote_delivery_done] 
  end
end
