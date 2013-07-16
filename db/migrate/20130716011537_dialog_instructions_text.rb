class DialogInstructionsText < ActiveRecord::Migration
  def change
    change_column :dialogs, :instructions, :text
    
  end
end
