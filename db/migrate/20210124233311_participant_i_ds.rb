class ParticipantIDs < ActiveRecord::Migration[5.2]
  def change
    add_column :participants, :account_uniq, :string, limit: 12, default: ''
    add_column :participants, :account_uniq_full, :string, limit: 64, default: ''
  end
end
