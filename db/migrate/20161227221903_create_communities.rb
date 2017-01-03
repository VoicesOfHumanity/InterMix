class CreateCommunities < ActiveRecord::Migration
  def change
    create_table :communities do |t|
      t.string :tagname   
      t.string :description  
      t.boolean  "twitter_post",             default: true
      t.string   "twitter_username",         limit: 255
      t.string   "twitter_oauth_token",      limit: 255
      t.string   "twitter_oauth_secret",     limit: 255
      t.string   "twitter_hash_tag",         limit: 255
      t.integer  "tweet_approval_min",       limit: 4,     default: 1
      t.string   "tweet_what",               limit: 255,   default: "roots"
      t.timestamps null: false
    end
    add_index :communities, ["tagname"]
  end
end
