class CreateApiRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :api_requests do |t|
      t.string :path
      t.text :request_body
      t.text :request_headers
      t.string :request_method
      t.string :request_content_type
      t.string :user_agent
      t.string :remote_ip
      t.string :our_function
      t.boolean :processed, default: false
      t.text :response_body
      t.string :account_uniq, limit: 12, default: ""
      t.integer :participant_id
      t.timestamps
    end
    add_index :api_requests, ["user_agent"]
    add_index :api_requests, ["remote_ip"]
    add_index :api_requests, ["our_function"]
    add_index :api_requests, ["participant_id"]
  end
end
