class PeriodSecond < ActiveRecord::Migration
  def change
    add_column :periods, :endposting, :date, :after=>:enddate
    add_column :periods, :endrating, :date, :after=>:endposting
    add_column :periods, :shortname, :string, :after=>:name
    add_column :periods, :description, :text
    add_column :periods, :metamaps, :text
    add_column :periods, :metamaps_frozen, :boolean, :default=>false
  end
end
