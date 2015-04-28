class MetamapNodeSum < ActiveRecord::Migration
  def change
    add_column :metamap_nodes, :sumcat, :boolean, default: false, after: :sortorder
  end
end
