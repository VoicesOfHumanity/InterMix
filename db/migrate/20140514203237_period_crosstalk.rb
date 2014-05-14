class PeriodCrosstalk < ActiveRecord::Migration
  def change
    add_column :periods, :crosstalk, :string, :default => 'none'
  end
end
