class CreateItemSubscribes < ActiveRecord::Migration
  def change
    create_table :item_subscribes do |t|
      t.integer :item_id
      t.integer :participant_id
    end
    add_index :item_subscribes, [:item_id, :participant_id]
    add_index :item_subscribes, [:participant_id, :item_id]
  end
end
