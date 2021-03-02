class CreateRemoteActors < ActiveRecord::Migration[5.2]
  def change
    create_table :remote_actors do |t|
      t.string :account
      t.string :account_url
      t.text :json_got
      t.string :username
      t.string :name
      t.text :summary
      t.string :inbox_url
      t.string :outbox_url
      t.string :icon_url
      t.string :image_url
      t.text :public_key
      t.datetime :last_fetch
      t.timestamps
    end
    add_index :remote_actors, [:account], length: {account: 30}
    add_index :remote_actors, [:account_url], length: {account: 30}
    add_index :remote_actors, [:name], length: {account: 30}
    add_column :follows, :followed_remote_actor_id, :integer
    add_column :follows, :following_remote_actor_id, :integer
  end
end
