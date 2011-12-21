class CreateItems < ActiveRecord::Migration
  def self.up
    create_table :items do |t|
      t.string :item_type
      t.integer :posted_by
      t.integer :group_id
      t.integer :dialog_id
      t.integer :dialog_round_id
      t.integer :subject_id
      t.boolean :promoted_to_forum
      t.string :election_area_type
      t.string :moderation_status
      t.datetime :moderated_at
      t.datetime :moderated_by
      t.text :html_content
      t.text :xml_content
      t.timestamps
    end
    add_index :items, :created_at
    add_index :items, [:posted_by, :created_at]
    add_index :items, [:dialog_id, :created_at]
    add_index :items, [:group_id, :created_at]
  end

  def self.down
    drop_table :items
  end
end
