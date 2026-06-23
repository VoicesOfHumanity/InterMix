# Deliver new posts to remote followers

require File.dirname(__FILE__)+'/cron_helper'

include ActivityPub

logger = @logger
logger.info("activitypub_delivery")

# Process a bounded batch per run so a large backlog can't blow up memory.
BATCH_LIMIT = (ENV['AP_DELIVERY_LIMIT'] || 200).to_i

items = Item.where(remote_delivery_done: false).order('id').limit(BATCH_LIMIT)
puts "#{items.length} items to process (limit #{BATCH_LIMIT})"

deliveries = 0

for item in items
  begin
    puts "##{item.id} : #{item.created_at} : #{item.subject}"

    # Decide whether this item should be federated at all.
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
      # Mark done and move on. (Previously execution fell through to the follows
      # lookup below and crashed on a nil participant for visitor/non-local posts.)
      puts " - skipping"
      item.remote_delivery_done = true
      item.save
      next
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

      # send_public_post now returns false (instead of raising) when delivery
      # fails, so a dead remote inbox no longer crashes the whole run.
      if send_public_post(item.participant, remote_actor, item)
        puts " - - - delivered"
        success += 1
        deliveries += 1
      else
        puts " - - - problem"
        failure += 1
      end
    end

    # Mark the item delivered regardless of per-follower failures: at-most-once
    # delivery. Leaving it false on failure caused the same item to be re-sent
    # every cron tick (the historical runaway send loop).
    item.remote_delivery_done = true
    item.save

  rescue => e
    # Never let one bad item abort the batch. Mark it done so we don't loop on it.
    puts " - ERROR on item ##{item.id}: #{e.class}: #{e}"
    logger.info("activitypub_delivery error on item ##{item.id}: #{e.class}: #{e}")
    begin
      item.remote_delivery_done = true
      item.save
    rescue => e2
      logger.info("activitypub_delivery could not mark item ##{item.id} done: #{e2}")
    end
  end
end

puts "#{deliveries} deliveries for #{items.length} items"
