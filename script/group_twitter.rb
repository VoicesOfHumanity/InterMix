#-- group_twitter.rb ---- send group items out by twitter that fit the criteria set for the group

require File.dirname(__FILE__)+'/cron_helper'

require 'open-uri'
require 'json'

ago = Time.now - 14*86400   # two weeks
items = Item.where("group_id>0 and tweeted_group=0 and created_at>?",ago).includes(:group,:dialog)

puts "#{items.length} items to consider"
tweeted = 0

items.each do |item|
  next if not item.group or not item.group.twitter_post or item.group.twitter_oauth_token == ''
  next if item.short_content.to_s == ''
  next if item.posted_by.to_i == 0

  puts "#{item.id}: \"#{item.subject}\" in group #{item.group_id}"

  if not item.is_first_in_thread and item.group.tweet_what == 'roots'
    puts "  is not a root message"
    next
  end  
  if not item.approval > 0
    puts "  insufficient approval (#{item.approval.to_i})"
    next
  else
    #-- Overall approval is positive, but we need to count how many positive approval ratings there are
    num_approvals = Rating.where(:item_id=>item.id).where("approval>0").count
    if not num_approvals >= item.group.tweet_approval_min
      puts "  insufficient # of approvals (#{num_approvals})"
      next
    end  
  end  

  if item.dialog and item.dialog.shortname.to_s != '' and item.group.shortname.to_s != ''
    domain = "#{item.dialog.shortname}.#{item.group.shortname}.#{ROOTDOMAIN}"
  elsif item.group and item.group.shortname.to_s != ''
    domain = "#{item.group.shortname}.#{ROOTDOMAIN}"
  elsif item.dialog and item.dialog.shortname.to_s != ''
    domain = "#{item.dialog.shortname}.#{ROOTDOMAIN}"
  else
    domain = BASEDOMAIN
  end    
  permalink = "http://#{domain}/items/#{item.id}/view"  
  
  # Format is: "text #dialog #hash url"
  
  txt = ""
  
  if item.dialog and item.dialog.twitter_hash_tag.to_s != ''
    tag = item.dialog.twitter_hash_tag
    tag = tag[1,99] if tag[0,1] == '#'
    txt += " ##{tag}"
  end  
  if item.group.twitter_hash_tag.to_s != ''
    tag = item.group.twitter_hash_tag
    tag = tag[1,99] if tag[0,1] == '#'
    txt += " ##{tag}"
  end  

  #-- Get the shortened url from bitly
  shorturl = ''
  bitlyurl = "https://api-ssl.bitly.com/v3/shorten?access_token=#{BITLY_TOKEN}&longUrl=" + Rack::Utils.escape(permalink)
  begin
    bitly_response = open(bitlyurl).read
    # { "data": [ ], "status_code": 500, "status_txt": "INVALID_ARG_ACCESS_TOKEN" }
    # { "status_code": 200, "status_txt": "OK", "data": { "long_url": "http:\/\/test2g.intermix.dev\/items\/1805\/view", "url": "http:\/\/j.mp\/1imMKf8", "hash": "1imMKf8", "global_hash": "1imMKf9", "new_hash": 0 } }
    if bitly_response != ''
      bitdata = JSON.parse(bitly_response)
      if bitdata and bitdata.has_key?("status_code") and bitdata['status_code'] == 200
         shorturl = bitdata['data']['url']
      else
        puts "  ERROR shortening: " + bitly_response
      end 
    else
      puts "  ERROR shortening: empty response"      
    end    
  rescue Exception => e
    puts "  ERROR shortening: " + e.message
    Rails.logger.info("group_twitter problem shortening #{permalink}")
    shorturl = ''
  end    
  if shorturl != ''
    txt += " #{shorturl}"
  end  
  
  wantlength = 140 - txt.length
  txt = item.short_content[0,wantlength] + txt
  
  puts "  should be tweeted: #{txt}"
  
  begin
    Twitter.configure do |config|
      config.consumer_key = TWITTER_CONSUMER_KEY
      config.consumer_secret = TWITTER_CONSUMER_SECRET
      config.oauth_token = item.group.twitter_oauth_token
      config.oauth_token_secret = item.group.twitter_oauth_secret
    end
    Twitter.update(txt)
    puts "  was tweeted"
    item.tweeted_group = true
    item.tweeted_group_at = Time.now
    item.save
    Rails.logger.info("group_twitter posted #{item.id} to twitter")
    tweeted += 1
  rescue Exception => e
    puts "  ERROR tweeting: " + e.message
    Rails.logger.info("group_twitter problem posting #{item.id} to twitter")
    if e.message == "Status is a duplicate."
      puts "  Marking as having been done"
      item.tweeted_group = true
      item.tweeted_group_at = Time.now
      item.save
    end  
  end 

end 

puts "done. #{tweeted} tweeted"

