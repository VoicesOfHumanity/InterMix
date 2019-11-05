class CreateSysData < ActiveRecord::Migration[5.2]
  def change
    create_table :sys_data do |t|
      t.integer :cur_moon_id
      t.string :moon_new_or_full, default: "new"
      t.datetime :moon_startdate
      t.datetime :moon_enddate
      t.string :together_apart, default: "apart"
      t.timestamps
    end
  end
end
