class ItemEmailTo < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :comment_email_to, :string, default: 'author'
  end
end
