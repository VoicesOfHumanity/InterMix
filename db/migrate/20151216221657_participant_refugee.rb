class ParticipantRefugee < ActiveRecord::Migration
  def change
    add_column :participants, :refugee, :boolean, :default => false
  end
end
