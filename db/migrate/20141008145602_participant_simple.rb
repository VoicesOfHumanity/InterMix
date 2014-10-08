class ParticipantSimple < ActiveRecord::Migration
  def change
    add_column :participants, :disc_interface, :string, :default=>'simple'
  end
end
