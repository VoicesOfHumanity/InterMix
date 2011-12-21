class CreateTemplates < ActiveRecord::Migration
  def self.up
    create_table :templates do |t|
      t.string :name
      t.string :section, :limit=>20
      t.string :mail_web, :limit=>4
      t.string :title
      t.text :html_body
      t.text :footer
      t.integer	:dialog_id
      t.integer :group_id
      t.integer :round_id
      t.timestamps
    end
    add_index :templates, :section
    add_index :templates, :group_id
    add_index :templates, :dialog_id
    add_index :templates, :round_id
  end

  def self.down
    drop_table :templates
  end
end
