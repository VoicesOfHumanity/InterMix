class ItemTopic < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :topic, :string
  end
end
