class ParticipPasswordReset < ActiveRecord::Migration
  def up
    change_column :participants, :reset_password_sent_at, :time
  end

  def down
    change_column :participants, :reset_password_sent_at, :string
  end
end
