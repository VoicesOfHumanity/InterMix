class ParticipPasswordReset2 < ActiveRecord::Migration
  def up
    change_column :participants, :reset_password_sent_at, :datetime
  end

  def down
    change_column :participants, :reset_password_sent_at, :time
  end
end
