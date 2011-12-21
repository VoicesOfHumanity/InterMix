class ParticNoMail < ActiveRecord::Migration
  def self.up
    add_column :participants, :no_email, :boolean, :default => false, :after=>"system_email"
  end

  def self.down
    remove_column :participants, :no_email
  end
end
