class CreateGeocountries < ActiveRecord::Migration
  def self.up
    create_table :geocountries do |t|
      t.string   "iso",           :limit => 2
      t.string   "iso3",          :limit => 3
      t.integer  "isonum"
      t.string   "fips",          :limit => 2
      t.string   "name"
      t.string   "capital"
      t.string   "area"
      t.integer  "population"
      t.string   "continent",     :limit => 2
      t.string   "tld",           :limit => 3
      t.string   "currency_code", :limit => 3
      t.string   "currency_name"
      t.integer  "phone"
      t.string   "zip_format"
      t.string   "zip_regex"
      t.string   "languages"
      t.integer  "geoname_id"
      t.string   "neighbors"
      t.string   "fips_equiv"
      t.timestamps
    end
    add_index "geocountries", ["iso"], :name => "iso"
    add_index "geocountries", ["name"], :name => "name"
  end

  def self.down
    drop_table :geocountries
  end
end
