class CreateGeoadmin2s < ActiveRecord::Migration
  def self.up
    create_table :geoadmin2s do |t|
      t.string  "admin2uniq",   :limit => 30
      t.string  "country_code", :limit => 2
      t.string  "admin1_code",  :limit => 10
      t.string  "admin2_code",  :limit => 15
      t.string  "name"
      t.string  "name_ascii"
      t.integer "geoname_id"
      t.string  "admin1uniq",   :limit => 15
    end
    add_index "geoadmin2s", ["admin1uniq"], :name => "admin1uniq"
    add_index "geoadmin2s", ["country_code", "admin1_code", "admin2_code"], :name => "admin2_code"
    add_index "geoadmin2s", ["country_code", "name"], :name => "geoadmin2s_name_index"
  end

  def self.down
    drop_table :geoadmin2s
  end
end
