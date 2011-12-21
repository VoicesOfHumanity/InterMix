class CreateRatings < ActiveRecord::Migration
  def self.up
    create_table :ratings do |t|
      t.integer :item_id
      t.integer :participant_id
      t.string :rating_type, :limit => 15
      t.integer :group_id
      t.integer :dialog_id
      t.integer :dialog_round_id
      t.integer :approval
      t.integer :interest
      t.timestamps
    end
    add_index :ratings, [:item_id,:id]
    add_index :ratings, [:participant_id,:id]
    add_index :ratings, [:group_id,:id]
  end

  def self.down
    drop_table :ratings
  end
end
