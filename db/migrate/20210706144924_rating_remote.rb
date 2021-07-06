class RatingRemote < ActiveRecord::Migration[5.2]
  def change
    add_column :ratings, :remote_actor_id, :integer, after: :participant_id
    add_index :ratings, [:remote_actor_id, :id] 
  end
end
