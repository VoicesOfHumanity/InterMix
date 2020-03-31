class CreateCommunityNetworks < ActiveRecord::Migration[5.2]
  def change
    create_table :community_networks do |t|
      t.integer "community_id"
      t.integer "network_id"
      t.integer "created_by"
      t.timestamps
    end
    add_index "community_networks", ["community_id", "network_id"]
    add_index "community_networks", ["network_id", "community_id"]
  end
end
