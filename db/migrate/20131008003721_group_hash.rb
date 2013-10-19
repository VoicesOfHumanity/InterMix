class GroupHash < ActiveRecord::Migration
  def change
    add_column :groups, :twitter_hash_tag, :string, :after => :twitter_oauth_secret
    add_column :dialogs, :twitter_hash_tag, :string
  end
end
