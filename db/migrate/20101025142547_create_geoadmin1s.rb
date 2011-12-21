class CreateGeoadmin1s < ActiveRecord::Migration
  def self.up
    create_table :geoadmin1s do |t|
      t.string  "admin1uniq",   :limit => 15
      t.string  "country_code", :limit => 2
      t.string  "admin1_code",  :limit => 10
      t.string  "name"
      t.boolean "has_admin2s"
    end
    add_index "geoadmin1s", ["country_code", "admin1_code"], :name => "admin1_code"
    add_index "geoadmin1s", ["country_code", "name"], :name => "geoadmin1s_name_index"
  end

  def self.down
    drop_table :geoadmin1s
  end
end
