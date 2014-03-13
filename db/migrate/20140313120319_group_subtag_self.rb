class GroupSubtagSelf < ActiveRecord::Migration
  def change
    add_column :group_subtags, :selfadd, :boolean, :default => true
    add_column :group_subtags, :description, :text
  end
end
