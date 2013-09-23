class GroupTweetLevel < ActiveRecord::Migration
  def change
    add_column :groups, :tweet_approval_min, :integer, :default=>1
    add_column :groups, :tweet_what, :string, :default=>'roots'
    add_column :items, :tweeted_user, :boolean, :default=>false
    add_column :items, :tweeted_user_at, :datetime
    add_column :items, :tweeted_group, :boolean, :default=>false
    add_column :items, :tweeted_group_at, :datetime
  end
end
