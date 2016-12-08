class CheckBoxes < ActiveRecord::Migration
  def change
    add_column :participants, :check_boxes, :text
  end
end
