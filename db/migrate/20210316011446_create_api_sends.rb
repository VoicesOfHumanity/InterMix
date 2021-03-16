class CreateApiSends < ActiveRecord::Migration[5.2]
  def change
    create_table :api_sends do |t|
      t.integer :participant_id
      t.integer :remote_actor_id
      t.string :to_url
      t.string :request_method
      t.text :request_headers
      t.text :request_object      
      t.integer :response_code
      t.text :response_body
      t.string :our_function
      t.boolean :processed, default: false
      t.timestamps
    end
    add_index :api_sends, ["our_function"]
    add_index :api_sends, ["participant_id"]
    add_index :api_sends, ["remote_actor_id"]
  end
end
