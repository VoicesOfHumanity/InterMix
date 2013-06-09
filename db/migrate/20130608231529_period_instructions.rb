class PeriodInstructions < ActiveRecord::Migration
  def change
    add_column :periods, :instructions, :text, :after => :shortdesc
  end
end
