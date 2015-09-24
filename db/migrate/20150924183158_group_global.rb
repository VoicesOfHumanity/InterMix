class GroupGlobal < ActiveRecord::Migration
  def change
    add_column :groups, :is_global, :boolean, default: false, after: :is_network
  end
end
