#-- group_twitter.rb ---- send group items out by twitter that fit the criteria set for the group

require File.dirname(__FILE__)+'/cron_helper'


ago = Time.now - 86400
items = Item.where("group_id>0 not tweeted_group and created_at>?",ago).includes(:group)

items.each do |item|
  next if not item.group or not item.group.twitter_post or item.group.twitter_oauth_token == ''
  next if item.short_content.to_s == ''
  next if item.posted_by.to_i == 0

  puts "#{item.id}: \"#{item.subject}\" in group #{item.group_id}"

  if not item.is_first_in_thread and item.group.tweet_what == 'roots'
    puts "  is not a root message"
    next
  end  
  if not item.approval >= item.group.tweet_approval_min
    puts "  insufficient approval (#{item.approval.to_i})"
    next
  end  
  
  puts "  should be tweeted"
  
  item.group.twitter_hash_tag
  
  
  begin
    Twitter.configure do |config|
      config.consumer_key = TWITTER_CONSUMER_KEY
      config.consumer_secret = TWITTER_CONSUMER_SECRET
      config.oauth_token = item.group.twitter_oauth_token
      config.oauth_token_secret = item.group.twitter_oauth_secret
    end
    Twitter.update(item.short_content)
    puts "  was tweeted"
    item.tweeted_group = true
    item.tweeted_group_at = Time.now
    item.save
    logger.info("group_twitter posted #{item.id} to twitter")
  rescue
    puts "  ERROR"
    logger.info("group_twitter problem posting #{item.id} to twitter")
  end 

end 

