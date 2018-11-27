class CreateConversationCommunities < ActiveRecord::Migration[5.2]
  def change
    create_table :conversation_communities do |t|
      t.integer :conversation_id
      t.integer :community_id
      t.timestamps
    end
    add_index :conversation_communities, [:conversation_id, :community_id], name: 'conv_com_ids'
    add_index :conversation_communities, [:community_id, :conversation_id], name: 'com_conv_ids'
  end
end
