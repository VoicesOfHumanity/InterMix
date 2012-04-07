class MessageTemplate < ActiveRecord::Migration
  def change
    add_column :messages, :mail_template, :string
  end
end
