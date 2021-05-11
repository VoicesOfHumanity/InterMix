class MessageExt < ActiveRecord::Migration[5.2]
  def change
    add_column :messages, :int_ext, :string, default: 'int'
    add_column :messages, :from_remote_actor_id, :integer, after: :from_participant_id
    add_column :messages, :to_remote_actor_id, :integer, after: :to_group_id
    add_index :messages, [:from_remote_actor_id]
    add_index :messages, [:to_remote_actor_id]
  end
end
