class NetworkGeoId < ActiveRecord::Migration[5.2]
  def change
    add_column :networks, :geo_level_id, :string, default: ''
  end
end
