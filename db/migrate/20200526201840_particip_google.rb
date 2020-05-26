class ParticipGoogle < ActiveRecord::Migration[5.2]
  def change
    add_column :participants, :google_uid, :string, default: ''
  end
end
