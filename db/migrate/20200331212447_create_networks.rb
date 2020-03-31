class CreateNetworks < ActiveRecord::Migration[5.2]
  def change
    create_table :networks do |t|
      t.string "name"
      t.integer "created_by"
      t.timestamps
    end
    add_index "networks", ["name"], name: "name"
    add_index "networks", ["created_by"], name: "created_by"
  end
end
