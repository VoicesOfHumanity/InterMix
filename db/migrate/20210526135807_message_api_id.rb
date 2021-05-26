class MessageApiId < ActiveRecord::Migration[5.2]
  def change
    add_column :messages, :api_request_id, :integer
    add_column :follows, :api_request_id, :integer
  end
end
