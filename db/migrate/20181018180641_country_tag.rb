class CountryTag < ActiveRecord::Migration[5.1]
  def change
    add_column :communities, :context, :string, default: ''
    add_column :communities, :context_code, :string, default: ''
  end
end
