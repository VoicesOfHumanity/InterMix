class MetamapBinary < ActiveRecord::Migration
  def change
    add_column :metamaps, :binary, :boolean, default: false
    add_column :metamap_nodes, :binary_on, :boolean, default: false
  end
end
