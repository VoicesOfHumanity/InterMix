class TwitterAccounts < ActiveRecord::Migration
  def self.up
    add_column :groups, :twitter_post, :boolean, :default => true
    add_column :groups, :twitter_username, :string
    add_column :groups, :twitter_oauth_token, :string
    add_column :groups, :twitter_oauth_secret, :string
    add_column :participants, :twitter_post, :boolean, :default => true
    add_column :participants, :twitter_username, :string
    add_column :participants, :twitter_oauth_token, :string
    add_column :participants, :twitter_oauth_secret, :string
  end

  def self.down
    remove_column :groups, :twitter_post
    remove_column :groups, :twitter_username
    remove_column :groups, :twitter_oauth_token
    remove_column :groups, :twitter_oauth_secret
    remove_column :participants, :twitter_post
    remove_column :participants, :twitter_username
    remove_column :participants, :twitter_oauth_token
    remove_column :participants, :twitter_oauth_secret
  end
end
