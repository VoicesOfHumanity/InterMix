class OldEmail < ActiveRecord::Migration
  def change
    add_column :participants, :old_email, :string, :after => :email 
  end
end
