class ItemsOutside < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :outside_com_post, :boolean, default: false, after: :intra_conv
    add_column :items, :outside_com_details, :text, after: :outside_com_post
  end
end
