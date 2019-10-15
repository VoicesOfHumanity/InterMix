class GeonameIndex < ActiveRecord::Migration[5.2]
  def change
    remove_index :geonames, name: 'admin_code'
    add_index :geonames, [:country_code,:admin1_code,:admin2_code]
  end
end
