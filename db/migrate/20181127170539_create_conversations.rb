class CreateConversations < ActiveRecord::Migration[5.2]
  def change
    create_table :conversations do |t|
      t.string :name
      t.string :shortname
      t.text :description
      t.text :front_template
      t.string :context, default: ""
      t.string :context_code, default: ""
      t.timestamps
    end
    add_index :conversations, [:shortname]
    add_index :conversations, [:name]
    add_index :conversations, [:context_code, :context]
  end
end
