class ComParFields < ActiveRecord::Migration[5.2]
  def change
    add_column :community_participants, :community_id, :integer
    add_column :community_participants, :participant_id, :integer
    add_index :community_participants, [:community_id,:participant_id], :unique => true
    add_index :community_participants, [:participant_id,:community_id], :unique => true
  end
end
