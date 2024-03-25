class CreateCommunityParticipants < ActiveRecord::Migration[5.2]
  def change
    create_table :community_participants do |t|

      t.timestamps
    end
  end
end
