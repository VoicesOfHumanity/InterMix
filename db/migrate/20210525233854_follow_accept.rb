class FollowAccept < ActiveRecord::Migration[5.2]
  def change
    add_column :follows, :accepted, :boolean, default: false
    add_column :follows, :accept_record_id, :integer
    add_column :follows, :remote_reference, :string
  end
end
