class PeriodResult < ActiveRecord::Migration
  def change
    add_column :periods, :result, :text
  end
end
