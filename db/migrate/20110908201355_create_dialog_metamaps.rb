class CreateDialogMetamaps < ActiveRecord::Migration
  def self.up
    remove_column :dialogs, :metamap_id
    create_table :dialog_metamaps do |t|
      t.integer :dialog_id
      t.integer :metamap_id
      t.integer :sortorder
      t.timestamps
    end
    add_index :dialog_metamaps, [:dialog_id,:metamap_id]
    add_index :dialog_metamaps, [:metamap_id,:dialog_id]
  end

  def self.down
    drop_table :dialog_metamaps
  end
end
