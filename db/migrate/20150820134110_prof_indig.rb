class ProfIndig < ActiveRecord::Migration
  def change
    add_column :participants, :indigenous, :boolean, :default => false
    add_column :participants, :other_minority, :boolean, :default => false
  end
end
