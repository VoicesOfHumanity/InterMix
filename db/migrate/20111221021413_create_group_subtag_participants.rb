class CreateGroupSubtagParticipants < ActiveRecord::Migration
  def change
    create_table :group_subtag_participants do |t|
      t.integer :group_subtag_id
      t.integer :group_id
      t.integer :participant_id
      t.timestamps
    end
    add_index :group_subtag_participants, [:group_subtag_id]
    add_index :group_subtag_participants, [:participant_id]
  end
end
