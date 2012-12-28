class ParticipantNewSignup < ActiveRecord::Migration
  def change
    add_column :participants, :new_signup, :boolean, :default=>true
  end
end
