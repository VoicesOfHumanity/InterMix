class ItemOutside < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :outside_conv_reply, :boolean, default: false
  end
end
