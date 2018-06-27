class CreateMoons < ActiveRecord::Migration[5.1]
  def change
    create_table :moons do |t|
      t.date :mdate
      t.string :topic
      t.text :top_text
      t.text :bottom_text
      t.string :new_or_full, default: 'new'
      t.timestamps
    end
    add_index "moons", ["mdate"]
  end
end
