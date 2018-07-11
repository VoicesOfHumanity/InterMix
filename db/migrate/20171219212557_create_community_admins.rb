class CreateCommunityAdmins < ActiveRecord::Migration[4.2]
  def change
    create_table :community_admins do |t|
      t.integer  :community_id, limit: 4
      t.integer  :participant_id, limit: 4
      t.boolean  :active, default: true
      t.boolean  :admin, default: false
      t.boolean  :moderator, default: true
      t.timestamps null: false
    end
    add_index "community_admins", ["community_id", "participant_id"]
  end
end
