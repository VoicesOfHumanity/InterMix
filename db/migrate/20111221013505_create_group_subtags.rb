class CreateGroupSubtags < ActiveRecord::Migration
  def change
    create_table :group_subtags do |t|
      t.integer :group_id
      t.string :tag, :limit => 30
      t.timestamps
    end
    add_index :group_subtags, [:group_id,:tag]
  end
end
