class GroupInstructions < ActiveRecord::Migration
  def change
    add_column :groups, :instructions, :string, :after => :shortdesc    
    add_column :dialogs, :instructions, :string, :after => :shortdesc      
  end
end
