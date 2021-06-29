# Deliver new posts to remote followers

require File.dirname(__FILE__)+'/cron_helper'

include ActivityPub

logger = @logger
logger.info("activitypub_delivery")


items = Item.where(remote_delivery_done: false).order('id')
puts "#{items.length} items to process"

deliveries = 0

for item in items
  puts "##{item.id} : #{item.created_at} : #{item.subject}"
    
  skip_it = true
  
  if item.posted_by.to_i == 0 or not item.participant
    puts " - Not posted by local user"
  elsif item.participant.status == 'visitor'
    puts " - Visitor post"
  elsif item.intra_com != 'public'
    puts " - for community only"
  elsif item.intra_conv != 'public'
    puts " - for conversation only"
  else
    skip_it = false
  end
  
  if skip_it
    puts " - skipping"
    item.remote_delivery_done = true
    item.save
  end
  
  follows = item.participant.followeds.where("following_remote_actor_id is not null and following_remote_actor_id>0")
  puts " - #{follows.length} remote followers"
  success = 0
  failure = 0
  for follow in follows
    if not follow.remote_follower
      puts " - - ##{follow.following_remote_actor_id} remote actor not found"
      next
    end
    remote_actor = follow.remote_follower
    puts " - - #{remote_actor.account}"
    
    if send_public_post(item.posted_by, remote_actor, item)
      puts " - - - delivered"
      success += 1
      deliveries += 1
    else
      puts " - - - problem"
      failure += 1
    end
  end
  
  item.remote_delivery_done = true
  item.save
    
end

puts "#{deliveries} deliveries for #{items.length} items"