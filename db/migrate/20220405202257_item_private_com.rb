class ItemPrivateCom < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :visible_com, :string, default: "public", after: :intra_com
  end
end
