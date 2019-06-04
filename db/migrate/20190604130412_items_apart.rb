class ItemsApart < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :together_apart, :string, default: ''
  end
end
