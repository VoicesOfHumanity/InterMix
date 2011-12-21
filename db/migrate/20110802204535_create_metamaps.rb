class CreateMetamaps < ActiveRecord::Migration
  def self.up
    create_table :metamaps do |t|
      t.string    :name
      t.integer   :created_by
      t.timestamps
    end
    add_index :metamaps, [:name], :length=>20
    add_index :metamaps, [:created_by]    
    add_index :metamaps, [:created_at]    
  end

  def self.down
    drop_table :metamaps
  end
end
