class MetamapNodesGroupName < ActiveRecord::Migration
  def change
    add_column :metamap_nodes, :name_as_group, :string, :after=>:name
  end
end
