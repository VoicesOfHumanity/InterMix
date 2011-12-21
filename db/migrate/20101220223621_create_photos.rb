class CreatePhotos < ActiveRecord::Migration
  def self.up
    create_table :photos do |t|
      t.integer :participant_id
      t.text :caption
      t.string :filename
      t.integer :filesize
      t.integer :width
      t.integer :height
      t.string :filetype, :limit=>3
      t.timestamps
    end
    add_index :photos, :participant_id
  end

  def self.down
    drop_table :photos
  end
end
