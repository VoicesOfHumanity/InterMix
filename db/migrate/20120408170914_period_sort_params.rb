class PeriodSortParams < ActiveRecord::Migration
  def change
    add_column :periods, :sort_metamap_id, :integer
    add_column :periods, :sort_order, :string, :default=>'date'
  end
end
