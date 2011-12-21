class CreateDialogAdmins < ActiveRecord::Migration
  def self.up
    create_table :dialog_admins do |t|
      t.integer :dialog_id
      t.integer :participant_id
      t.boolean :active, :default => true
      t.timestamps
    end
    add_index :dialog_admins, [:dialog_id, :participant_id]
    add_column :participants, :old_user_id, :integer
    add_index :participants, [:old_user_id]
  end

  def self.down
    drop_table :dialog_admins
    remove_column :participants, :old_user_id
  end
end
