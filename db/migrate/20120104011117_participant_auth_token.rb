class ParticipantAuthToken < ActiveRecord::Migration
  def up
    add_column :participants, :authentication_token, :string
  end

  def down
    remove_column :participant, :authentication_token
  end
end
