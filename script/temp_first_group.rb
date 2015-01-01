# encoding: utf-8

# Set the group_id of the first in thread for items

require File.dirname(__FILE__)+'/cron_helper'

items = Item.where(nil)

for item in items
  if item.is_first_in_thread
    item.first_in_thread_group_id = item.group_id
    item.save
  elsif item.first_in_thread.to_i > 0
    first_item = Item.find_by_id(item.first_in_thread)
    item.first_in_thread_group_id = first_item.group_id if first_item
    item.save
  end
  
end