class CreateDialogGroups < ActiveRecord::Migration
  def self.up
    create_table :dialog_groups do |t|
      t.integer :dialog_id
      t.integer :group_id
      t.boolean :active, :default => true
      t.timestamps
    end
    add_index :dialog_groups, [:dialog_id, :group_id]
    add_index :dialog_groups, [:group_id, :dialog_id]
  end

  def self.down
    drop_table :dialog_groups
  end
end
