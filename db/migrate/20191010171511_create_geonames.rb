class CreateGeonames < ActiveRecord::Migration[5.2]
  def change
    create_table "geonames", force: :cascade do |t|
      t.string  "name",              limit: 255
      t.string  "asciiname",         limit: 255
      t.text    "alternatenames",    limit: 65535
      t.decimal "latitude",                        precision: 11, scale: 6
      t.decimal "longitude",                       precision: 11, scale: 6
      t.string  "feature_class",     limit: 1
      t.string  "feature_code",      limit: 10
      t.string  "country_code",      limit: 2
      t.string  "cc2",               limit: 255
      t.string  "admin1_code",       limit: 20
      t.string  "admin2_code",       limit: 80
      t.string  "admin3_code",       limit: 20
      t.string  "admin4_code",       limit: 20
      t.integer "population",        limit: 8
      t.integer "elevation",         limit: 4
      t.integer "gtopo30",           limit: 4
      t.string  "timezone",          limit: 255
      t.date    "modification_date"
      t.string  "fclasscode",        limit: 7
    end
    add_index "geonames", ["admin1_code", "admin2_code"], name: "admin_code", using: :btree
    add_index "geonames", ["feature_class", "feature_code"], name: "feature", using: :btree
    add_index "geonames", ["latitude"], name: "latitude", using: :btree
    add_index "geonames", ["longitude"], name: "longitude", using: :btree
    add_index "geonames", ["name"], name: "geonames_name_index", length: {"name"=>30}, using: :btree
  end
end
