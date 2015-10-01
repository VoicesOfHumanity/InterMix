class ParticVeteran < ActiveRecord::Migration
  def change
    add_column :participants, :veteran, :boolean, :default => false
    add_column :participants, :interfaith, :boolean, :default => false
  end
end
