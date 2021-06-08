class MessageRemoteId < ActiveRecord::Migration[5.2]
  def change
    add_column :messages, :remote_reference, :string
  end
end
