class ItemRepConv < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :representing_com, :string
  end
end
