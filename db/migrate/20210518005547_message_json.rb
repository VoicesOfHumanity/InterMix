class MessageJson < ActiveRecord::Migration[5.2]
  def change
    add_column :messages, :received_json, :text
    add_column :api_requests, :problem, :boolean, default: false, after: :processed
    add_column :api_requests, :redo, :boolean, default: false, after: :problem
    add_index :participants, [:account_uniq]   
  end
end
