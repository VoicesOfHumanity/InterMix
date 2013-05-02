class ParticipantLastGroup < ActiveRecord::Migration
  def change
    add_column :participants, :last_group_id, :integer
    add_column :participants, :last_dialog_id, :integer
  end
end
