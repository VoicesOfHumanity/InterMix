class NetworkGeoDetail < ActiveRecord::Migration[5.2]
  def change
    add_column :networks, :geo_level_detail, :string, default: ''
  end
end
