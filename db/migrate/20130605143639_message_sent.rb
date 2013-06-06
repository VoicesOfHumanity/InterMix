class MessageSent < ActiveRecord::Migration
  def change
    add_column :messages, :email_sent, :boolean, :default =>false
    add_column :messages, :email_sent_at, :datetime
  end
end
