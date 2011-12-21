class CreatePeriods < ActiveRecord::Migration
  def change
    create_table :periods do |t|
      t.date :startdate
      t.date :enddate
      t.string :name
      t.string :group_dialog, :default=>"dialog"
      t.integer :group_id
      t.integer :dialog_id
      t.timestamps
    end
    add_index :periods, [:dialog_id,:startdate]
    add_index :periods, [:group_id,:startdate]
    add_column :items, :period_id, :integer
    add_column :ratings, :period_id, :integer
  end
end
