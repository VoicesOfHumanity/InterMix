class CreateGroupParticipants < ActiveRecord::Migration
  def self.up
    create_table :group_participants do |t|
      t.integer :group_id
      t.integer :participant_id
      t.boolean :moderator, :default=>false
      t.boolean :active, :default=>true
      t.timestamps
    end
    add_index :group_participants, [:group_id,:participant_id]
    add_index :group_participants, [:participant_id,:group_id]
  end

  def self.down
    drop_table :group_participants
  end
end
