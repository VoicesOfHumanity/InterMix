class MessageGroupDialog < ActiveRecord::Migration
  def change
    add_column :messages, :group_id, :integer
    add_column :messages, :dialog_id, :integer
  end
end
