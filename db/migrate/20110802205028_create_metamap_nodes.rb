class CreateMetamapNodes < ActiveRecord::Migration
  def self.up
    create_table :metamap_nodes do |t|
      t.integer :metamap_id
      t.string  :name
      t.integer :parent_id
      t.text    :description
      t.string  :sortorder
      t.timestamps
    end
    add_index :metamap_nodes, [:metamap_id,:sortorder], :length=>{:sortorder=>10}    
    add_index :metamap_nodes, [:parent_id]    
  end

  def self.down
    drop_table :metamap_nodes
  end
end
