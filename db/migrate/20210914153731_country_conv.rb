class CountryConv < ActiveRecord::Migration[5.2]
  def change
    add_column :conversations, :twocountry, :boolean, default: false
    add_column :conversations, :twocountry_country1, :integer
    add_column :conversations, :twocountry_country2, :integer
    add_column :conversations, :twocountry_supporter1, :integer
    add_column :conversations, :twocountry_supporter2, :integer
    add_column :conversations, :twocountry_common, :integer
  end
end
