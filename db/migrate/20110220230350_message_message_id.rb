class MessageMessageId < ActiveRecord::Migration
  def self.up
    add_column :messages, :message_id, :string
    add_index :messages, [:message_id], :length => {:message_id=>30}
  end

  def self.down
    remove_column :messages, :message_id
  end
end
