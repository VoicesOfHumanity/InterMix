class DialogWordLimit < ActiveRecord::Migration
  def change
    add_column :dialogs, :max_words, :integer, :after=>:max_characters
    add_column :periods, :max_words, :integer, :after=>:max_characters
  end
end
