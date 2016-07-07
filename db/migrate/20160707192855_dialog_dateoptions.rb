class DialogDateoptions < ActiveRecord::Migration
  def change
    add_column :dialogs, :default_datetype, :string, default: 'fixed'
    add_column :dialogs, :default_datefixed, :string, default: 'month'
    add_column :dialogs, :default_datefrom, :date
  end
end
