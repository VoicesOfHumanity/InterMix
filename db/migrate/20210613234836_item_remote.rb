class ItemRemote < ActiveRecord::Migration[5.2]
  
  def change
    add_column :items, :int_ext, :string, default: 'int', after: :media_type    
    add_column :items, :posted_by_remote_actor_id, :integer, after: :posted_by
    add_column :items, :remote_reference, :string
    add_column :items, :received_json, :text
    add_column :items, :api_request_id, :integer
    add_index :items, [:posted_by_remote_actor_id] 
  end
end
