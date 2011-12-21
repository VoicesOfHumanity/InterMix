class CreateDialogParticipants < ActiveRecord::Migration
  def self.up
    create_table :dialog_participants do |t|
      t.integer  "dialog_id"
      t.integer  "participant_id"
      t.boolean  "moderator",         :default => false
      t.boolean  "active",            :default => true
      t.string   "direct_email_code"
      t.timestamps
    end
    add_index "dialog_participants", ["direct_email_code"], :length => {"direct_email_code"=>20}
    add_index "dialog_participants", ["dialog_id", "participant_id"]
    add_index "dialog_participants", ["participant_id", "dialog_id"]
  end

  def self.down
    drop_table :dialog_participants
  end
end
