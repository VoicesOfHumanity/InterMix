class PeriodResultLonger < ActiveRecord::Migration
  def change
    change_column :periods, :result, :text, limit: 16777215
  end
end
