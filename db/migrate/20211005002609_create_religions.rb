class CreateReligions < ActiveRecord::Migration[5.2]
  def change
    create_table :religions do |t|
      t.string :name
      t.string :shortname
      t.string :subdiv, default: ''
      t.timestamps
    end
    add_index :religions, [:name], length: {name: 35}
  end
end
