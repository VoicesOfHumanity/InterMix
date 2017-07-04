require File.dirname(__FILE__)+'/cron_helper'

# Convert the old type of ratings to the thumb kind

ratings = Rating.all
puts "#{ratings.length} ratings"

for rating in ratings
  item_id = rating.item_id
  participant_id = rating.participant_id
  approval = rating.approval
  old_interest = rating.interest
  
  next if approval === nil 
  
  item = Item.find_by_id(item_id)
  next if not item
  
  # set the interest as the absolute value of approval (-3, -2, -1, 0, 1, 2, 3)
  rating.interest = rating.approval.abs
  
  # check for comments
  #com_count = Item.where(posted_by: participant_id, is_first_in_thread: false, first_in_thread: item_id).count
  com_count = Item.where(posted_by: participant_id, reply_to: item_id).count
  
  puts "rating:#{rating.id} by participant:#{participant_id} on item:#{item_id} with #{com_count} comments"
  
  if com_count > 0
    rating.interest = 4
    rating.group_id = item.group_id
    rating.dialog_id = item.dialog_id
    rating.dialog_round_id = item.dialog_round_id
  end
  
  if rating.interest != old_interest or com_count > 0
    puts " - approval:#{approval}"
    puts " - interest changed from #{old_interest} to #{rating.interest}"
    rating.save!
  end
  
end

items = Item.where("reply_to>0")
puts "#{items.length} reply items"

for item in items
  
  # Check if the item replied to has a rating with a 4 interest
  
  orig_item = Item.find_by_id(item.reply_to.to_i)
  
  next if not orig_item
  
  if item.first_in_thread.to_i > 0 and item.first_in_thread.to_i != item.reply_to.to_i
    root_item = Item.find_by_id(item.first_in_thread.to_i)
  else
    root_item = orig_item
  end
  
  next if not root_item
  
  # check and update rating for item we're replying to
  rating = Rating.where(item_id: orig_item.id, participant_id: item.posted_by.to_i, rating_type: 'AllRatings', group_id: orig_item.group_id, dialog_id: orig_item.dialog_id, dialog_round_id: orig_item.dialog_round_id).first_or_initialize  
  if rating.interest.to_i != 4
    rating.interest = 4
    rating.save
    puts "item #{orig_item.id} commented by #{item.posted_by.to_i} in #{item.id}. Was:#{rating.interest}. Root:#{item.first_in_thread}"
    puts " - reply interest set to 4"
  end

  if root_item.id !=  orig_item.id
    # check and update rating for root item, if different
    rating = Rating.where(item_id: root_item.id, participant_id: item.posted_by.to_i, rating_type: 'AllRatings', group_id: root_item.group_id, dialog_id: root_item.dialog_id, dialog_round_id: root_item.dialog_round_id).first_or_initialize  
    if rating.interest != 4
      rating.interest = 4
      rating.save
      #puts "item #{root_item.id} root commented by #{item.posted_by.to_i} in #{item.id}"
      puts " - root #{root_item.id} interest set to 4"
    end
  end
  
end

