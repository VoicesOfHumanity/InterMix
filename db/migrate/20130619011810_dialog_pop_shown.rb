class DialogPopShown < ActiveRecord::Migration
  def change
    add_column :participants, :dialog_pop_shown, :boolean, :after => :new_signup, :default => false
  end
end
