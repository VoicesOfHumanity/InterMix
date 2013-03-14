class CreateHelpTexts < ActiveRecord::Migration
  def change
    create_table :help_texts do |t|
      t.string :code
      t.string :description
      t.text :text
      t.timestamps
    end
    add_index "help_texts", ['code'], :length => {"code"=>30}
    
  end
end

