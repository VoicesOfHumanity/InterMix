class NetworkDefinition < ActiveRecord::Migration[5.2]
  def change
    add_column :networks, :communityarray, :text
    add_column :networks, :age, :integer, default: 0
    add_column :networks, :gender, :integer, default: 0
    add_column :networks, :geo_level, :integer, default: 0
  end
end
