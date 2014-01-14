#-- Set all messages in groups to subgroup none if they were posted without a subgroup the author is in

require File.dirname(__FILE__)+'/cron_helper'

items = Item.where("group_id > 0 and is_first_in_thread=1").all

processed = 0
changed = 0
replies_changed = 0

for item in items
  processed += 1
  xgroup = Group.find_by_id(item.group_id)
  if xgroup
    if item.subgroup_list.to_s == ''
      #-- If there's no subgroup set, use none
      item.subgroup_list = 'none'          
      item.save
      changed += 1
    else  
      #-- There is already one or more subgroups set. Check if the poster is in any of them.
      user = Participant.find_by_id(item.posted_by)
      if user
        users_subgroups = xgroup.mysubtags(user)
        insub = false
        for xsub in item.subgroup_list
          if users_subgroups.include?(xsub)
            insub = true
          end  
        end  
        if not insub and not item.subgroup_list.include?('none')
          item.subgroup_list.add('none')        
          item.save
          changed += 1
        end
      end  
    end 
  end
  replies = Item.where("first_in_thread=#{item.id} and is_first_in_thread=0").all
  for reply in replies
    reply.subgroup_list = item.subgroup_list
    reply.save
    replies_changed += 1
  end
end

puts "processed: #{processed}"
puts "changed: #{changed}"
puts "replies changed: #{replies_changed}"