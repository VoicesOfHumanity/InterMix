class ConversationTopic < ActiveRecord::Migration[5.2]
  def change
    add_column :conversations, :topics, :text
  end
end
