class ConversationApart < ActiveRecord::Migration[5.2]
  def change
    add_column :conversations, :together_apart, :string, default: 'apart'
  end
end
