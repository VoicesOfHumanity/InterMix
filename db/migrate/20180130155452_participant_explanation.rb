class ParticipantExplanation < ActiveRecord::Migration[5.1]
  def change
    add_column :participants, :explanation, :text
  end
end
