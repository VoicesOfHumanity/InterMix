class ItemSubscribeReverse < ActiveRecord::Migration
  def change
    add_column :item_subscribes, :followed, :boolean, default: true
  end
end
