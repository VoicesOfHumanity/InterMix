class ParticipMoreGeo < ActiveRecord::Migration
  def self.up
    add_column :participants, :admin2uniq, :string, :limit => 30, :after=>:city
    add_column :participants, :admin1uniq, :string, :limit => 15, :after=>:county_name    
    add_column :participants, :latitude, :decimal, :precision => 11, :scale => 6, :after=>:phone
    add_column :participants, :longitude, :decimal, :precision => 11, :scale => 6, :after=>:latitude
    add_column :participants, :timezone, :string, :after=>:longitude
    add_column :participants, :timezone_offset, :decimal, :precision => 5,  :scale => 1, :after=>:timezone
  end

  def self.down
    remove_column :participants, :admin2uniq
    remove_column :participants, :admin1uniq    
    remove_column :participants, :latitude
    remove_column :participants, :longitude
    remove_column :participants, :timezone
    remove_column :participants, :timezone_offset
  end
end
