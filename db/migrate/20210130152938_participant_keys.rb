class ParticipantKeys < ActiveRecord::Migration[5.2]
  def change
    add_column :participants, :private_key, :text
    add_column :participants, :public_key, :text
  end
end
