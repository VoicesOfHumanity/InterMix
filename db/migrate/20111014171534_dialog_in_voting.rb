class DialogInVoting < ActiveRecord::Migration
  def self.up
    add_column :dialogs, :in_voting_round, :boolean, :default => false
  end

  def self.down
    remove_column :dialogs, :in_voting_round
  end
end
