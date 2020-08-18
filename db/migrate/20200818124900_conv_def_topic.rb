class ConvDefTopic < ActiveRecord::Migration[5.2]
  def change
    add_column :conversations, :default_topic, :string
  end
end
