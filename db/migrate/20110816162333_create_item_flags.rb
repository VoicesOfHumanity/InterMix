class CreateItemFlags < ActiveRecord::Migration
  def self.up
    create_table :item_flags do |t|
      t.integer :item_id
      t.integer :participant_id
      t.text    :comment
      t.boolean :cleared, :default => false
      t.integer :moderator_id
      t.timestamps
    end
    add_index :item_flags, [:item_id,:participant_id]    
    add_index :item_flags, [:participant_id,:item_id]  
    add_index :item_flags, [:moderator_id,:item_id]  
    
    add_column :items, :is_flagged, :boolean, :default => false
      
  end

  def self.down
    drop_table :item_flags
    remove_column :items, :is_flagged
  end
end
