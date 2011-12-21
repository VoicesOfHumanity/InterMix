class CreateMetamapNodeParticipants < ActiveRecord::Migration
  def self.up
    create_table :metamap_node_participants do |t|
      t.integer :metamap_id
      t.integer :metamap_node_id
      t.integer :participant_id
      t.timestamps
    end
    add_index :metamap_node_participants, [:metamap_node_id,:participant_id], :name=>'node_particip'    
    add_index :metamap_node_participants, [:participant_id,:metamap_node_id], :name=>'particip_node'    
    add_index :metamap_node_participants, [:metamap_id,:metamap_node_id], :name=>'metamap_node'    
  end

  def self.down
    drop_table :metamap_node_participants
  end
end
