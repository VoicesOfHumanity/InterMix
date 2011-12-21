class CreateMetroAreas < ActiveRecord::Migration
  def self.up
    create_table :metro_areas do |t|
      t.string :name
      t.string :country_code
      t.integer :population
      t.integer :population_year
      t.timestamps
    end
    add_index :metro_areas, [:country_code,:name], :length=>{:country_code=>1,:name=>20}
  end

  def self.down
    drop_table :metro_areas
  end
end
