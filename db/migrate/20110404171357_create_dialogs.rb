class CreateDialogs < ActiveRecord::Migration
  def self.up
    create_table :dialogs do |t|
      t.string :name
      t.text :description
      t.text :coordinators
      t.string :visibility
      t.string :publishing
      t.integer :max_voting_distribution
      t.integer :max_characters
      t.timestamps
    end
    add_index :dialogs, [:name], :length => {:name=>30}   
  end

  def self.down
    drop_table :dialogs
  end
end
