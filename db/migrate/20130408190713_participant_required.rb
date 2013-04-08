class ParticipantRequired < ActiveRecord::Migration
  def change
    add_column :participants, :required_entered, :boolean, :default => false
  end
end
