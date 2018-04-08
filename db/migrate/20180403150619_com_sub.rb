class ComSub < ActiveRecord::Migration[5.1]
  def change
    add_column :communities, :is_sub, :boolean, default: false
    add_column :communities, :sub_of, :integer
  end
end
