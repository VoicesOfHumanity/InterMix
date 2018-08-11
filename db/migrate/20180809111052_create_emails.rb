class CreateEmails < ActiveRecord::Migration[5.1]
  def change
    create_table :emails do |t|
      t.integer :participant_id, :integer
      t.string :context, :string
      t.boolean :sent, default: false
      t.datetime :sent_at, :datetime
      t.boolean :seen, default: false
      t.datetime :seen_at, :datetime
      t.timestamps
    end    
    add_index :emails, [:participant_id, :id]
  end
end
