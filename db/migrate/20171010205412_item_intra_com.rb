class ItemIntraCom < ActiveRecord::Migration[4.2]
  def change
    add_column :items, :intra_com, :string, default: 'public'
  end
end
