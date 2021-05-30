class MessageFriend < ActiveRecord::Migration[5.2]
  def change
    add_column :messages, :to_friend_id, :integer, after: :to_remote_actor_id
  end
end
