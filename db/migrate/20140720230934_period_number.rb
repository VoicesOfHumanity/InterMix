class PeriodNumber < ActiveRecord::Migration
  def change
    add_column :periods, :period_number, :integer, :default => 0
  end
end
