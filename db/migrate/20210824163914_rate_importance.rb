class RateImportance < ActiveRecord::Migration[5.2]
  def change
    add_column :ratings, :importance, :integer, after: :interest
  end
end
