class RatingConv < ActiveRecord::Migration[5.2]
  def change
    add_column :ratings, :conversation_id, :integer
  end
end
