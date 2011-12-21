class ParticpLastUrl < ActiveRecord::Migration
  def self.up
    add_column :participants, :last_url, :string
  end

  def self.down
    remove_column :participants, :last_url
  end
end
