class CreateParticipantReligions < ActiveRecord::Migration[5.2]
  def change
    create_table :participant_religions do |t|
      t.integer :participant_id
      t.integer :religion_id
      t.string :religion_denomination
      t.timestamps
    end
    add_index :participant_religions, [:participant_id, :religion_id]
    add_index :participant_religions, [:religion_id, :participant_id]
  end
end
