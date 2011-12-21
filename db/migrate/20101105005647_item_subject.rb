class ItemSubject < ActiveRecord::Migration
  def self.up
    add_column :items, :subject, :string, :after=>:dialog_round_id
  end

  def self.down
    remove_column :items, :subject
  end
end
