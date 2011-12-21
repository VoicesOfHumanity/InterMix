class ParticMetroId < ActiveRecord::Migration
  def self.up
    add_column :participants, :metro_area_id, :integer, :after=>:metropolitan_area
    add_column :participants, :bioregion_id, :integer, :after=>:bioregion
    add_column :participants, :faith_tradition_id, :integer, :after=>:faith_tradition
    add_column :participants, :political_id, :integer, :after=>:political
  end

  def self.down
    remove_column :participants, :metro_area_id
    remove_column :participants, :bioregion_id
    remove_column :participants, :faith_tradition_id
    remove_column :participants, :political_id
  end
end
