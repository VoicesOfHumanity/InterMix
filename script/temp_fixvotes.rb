require File.dirname(__FILE__)+'/cron_helper'

# Convert the old type of ratings to the thumb kind

ratings = Rating.all

for rating in ratings
  item_id = rating.item_id
  participant_id = rating.participant_id
  approval = rating.approval
  old_interest = rating.interest
  
  next if approval === nil 
  
  # set the interest as the absolute value of approval (-3, -2, -1, 0, 1, 2, 3)
  rating.interest = rating.approval.abs
  
  # check for comments
  com_count = Item.where(posted_by: participant_id, is_first_in_thread: false, first_in_thread: item_id).count
  
  puts "rating:#{rating.id} by participant:#{participant_id} on item:#{item_id} with #{com_count} comments"
  
  if com_count > 0
    rating.interest = 4
  end
  
  if rating.interest != old_interest
    puts " - approval:#{approval}"
    puts " - interest changed from #{old_interest} to #{rating.interest}"
    rating.save!
  end
  
end
