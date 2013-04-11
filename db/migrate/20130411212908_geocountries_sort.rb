class GeocountriesSort < ActiveRecord::Migration
  def change
    add_column :geocountries, :extrasort, :string, :limit => 3
    add_index :geocountries, ["extrasort","name"], :name => "sortname"
  end
end
