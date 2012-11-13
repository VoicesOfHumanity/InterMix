class MetamapDefault < ActiveRecord::Migration
  def change
    add_column :metamaps, :global_default, :boolean, :default=>false
  end
end
