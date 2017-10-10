class ItemIntraCom < ActiveRecord::Migration
  def change
    add_column :items, :intra_com, :string, default: 'public'
  end
end
