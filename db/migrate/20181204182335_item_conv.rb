class ItemConv < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :conversation_id, :integer, after: :dialog_round_id
    add_column :items, :intra_conv, :string, default: 'public'
    add_index :items, [:conversation_id]
  end
end
