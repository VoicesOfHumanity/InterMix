class MoonTime < ActiveRecord::Migration[5.1]
  def change
    add_column :moons, :mtime, :string, limit: 5, default: '12:00'
  end
end
