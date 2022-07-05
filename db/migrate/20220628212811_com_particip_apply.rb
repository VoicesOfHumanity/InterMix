class ComParticipApply < ActiveRecord::Migration[5.2]
  def change
    add_column :community_participants, :status, :string, default: 'member'   # member, moderator, admin, applied, banned
  end
end
