class CreateMoonWinners < ActiveRecord::Migration[5.2]
  def change
    create_table :moon_winners do |t|
      t.integer :moon_id
      t.date :send_date
      t.string :new_or_full
      t.integer :gender_id
      t.integer :age_id
      t.string :category
      t.integer :item_id
      t.timestamps
    end
    add_index :moon_winners, [:moon_id]
    add_index :moon_winners, [:item_id]
    add_index :moon_winners, [:send_date]
  end
end
