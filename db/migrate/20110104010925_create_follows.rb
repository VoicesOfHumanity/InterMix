class CreateFollows < ActiveRecord::Migration
  def self.up
    create_table :follows do |t|
      t.integer :following_id
      t.integer :followed_id
      t.boolean :mutual, :default => false
      t.timestamps
    end
    add_index :follows, [:following_id, :followed_id]
    add_index :follows, [:followed_id, :following_id]
  end

  def self.down
    drop_table :follows
  end
end
