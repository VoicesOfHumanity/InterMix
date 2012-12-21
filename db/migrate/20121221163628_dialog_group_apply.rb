class DialogGroupApply < ActiveRecord::Migration
  def change
    add_column :dialog_groups, :apply_at, :datetime
    add_column :dialog_groups, :apply_by, :integer, :default=>0
    add_column :dialog_groups, :apply_status, :string, :default=>''
    add_column :dialog_groups, :processed_by, :integer, :default=>0
  end
end
