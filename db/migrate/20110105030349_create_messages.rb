class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.integer :from_participant_id
      t.integer :to_participant_id
      t.integer :to_group_id
      t.integer :template_id
      t.string :subject
      t.text :message
      t.string :sendmethod
      t.boolean :sent
      t.datetime :sent_at
      t.integer :response_to_id
      t.boolean :read_email
      t.boolean :read_web
      t.datetime :read_at
      t.boolean :sender_delete
      t.boolean :recipient_delete
      t.timestamps
    end
    add_index :messages, [:from_participant_id,:id]
    add_index :messages, [:to_participant_id,:id]
  end

  def self.down
    drop_table :messages
  end
end
