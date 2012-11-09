class CreateGroupMetamaps < ActiveRecord::Migration
  def change
    create_table :group_metamaps do |t|
      t.integer  :group_id
      t.integer  :metamap_id
      t.integer  :sortorder
      t.timestamps
    end
  end
end
