class CreateComplaints < ActiveRecord::Migration[5.2]
  def change
    create_table :complaints do |t|
      t.integer :item_id
      t.integer :poster_id
      t.integer :complainer_id
      t.string :reason
      t.string :status
      t.timestamps
    end
    add_index :complaints, [:item_id]
    add_index :complaints, [:poster_id]
    add_index :complaints, [:complainer_id]
  end
end
