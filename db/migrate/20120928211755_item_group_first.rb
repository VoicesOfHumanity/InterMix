class ItemGroupFirst < ActiveRecord::Migration
  def change
    add_column :items, :first_in_thread_group_id, :integer
  end
end
