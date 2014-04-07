class AddColumnsToParticipants < ActiveRecord::Migration
  def change
    add_column :participants, :provider, :string
    add_column :participants, :uid, :string
  end
end
