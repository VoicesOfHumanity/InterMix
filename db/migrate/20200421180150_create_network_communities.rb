class CreateNetworkCommunities < ActiveRecord::Migration[5.2]
  def change
    create_table :network_communities do |t|
      t.integer :network_id
      t.integer :community_id
      t.integer :created_by
      t.timestamps
    end
    add_index :network_communities, [:network_id, :community_id], name: 'net_com_ids'
    add_index :network_communities, [:community_id, :network_id], name: 'com_net_ids'
  end
end
