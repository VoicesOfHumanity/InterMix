class FollowsExternal < ActiveRecord::Migration[5.2]
  def change
    add_column :follows, :int_ext, :string, default: 'int'
    add_column :follows, :following_fulluniq, :string
    add_column :follows, :followed_fulluniq, :string
    add_index :follows, [:following_fulluniq,:followed_fulluniq], length: {following_fulluniq: 30, followed_fulluniq: 10}
    add_index :follows, [:followed_fulluniq, :following_fulluniq], length: {followed_fulluniq: 30, following_fulluniq: 10}
  end
end
