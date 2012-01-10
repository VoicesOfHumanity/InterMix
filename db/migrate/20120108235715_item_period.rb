class ItemPeriod < ActiveRecord::Migration
  def change
    add_column :participants, :reset_password_sent_at, :string, :after=>:reset_password_token 
    add_column :dialogs, :current_period, :integer 
    add_index :items, [:period_id,:id]
  end
end
