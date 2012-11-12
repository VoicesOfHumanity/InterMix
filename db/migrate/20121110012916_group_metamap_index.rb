class GroupMetamapIndex < ActiveRecord::Migration
  def change
    add_index :group_metamaps, ["group_id", "metamap_id"], :name => "index_group_metamaps_on_dialog_id_and_metamap_id"
    add_index :group_metamaps, ["metamap_id", "group_id"], :name => "index_group_metamaps_on_metamap_id_and_group_id"
    add_column :groups, :required_meta, :boolean, :default => true  
  end
end
