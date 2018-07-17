class MoonDone < ActiveRecord::Migration[5.1]
  def change
    add_column :moons, :mailing_sent, :boolean, default: false
  end
end
