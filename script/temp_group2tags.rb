require File.dirname(__FILE__)+'/cron_helper'
require 'optparse'

# Turn a specified group into some specified tags
# We will get the group ID and the tag(s)
# The tags will be applied as community @tags to the members, and message #tags to the messages

group_id = 0
tags =  ''

opts = OptionParser.new
opts.on("-gARG","--group=ARG",Integer) {|val| group_id = val.to_i}
opts.on("-tARG","--tags=ARG",String) {|val| tags = val.to_s}
opts.parse(ARGV)

if not group_id.to_i > 0
  puts "Group ID is missing"
  exit
end

group = Group.find_by_id(group_id)
if not group
  puts "Couldn't find group ##{group_id}"
  exit
end

puts "Group ##{group.id}: #{group.name}"

group_participants = GroupParticipant.where(group_id: group_id).includes(:participant)
puts "#{group_participants.length} members"
for group_participant in group_participants
  participant = group_participant.participant
  puts "##{participant.id}: #{participant.name}"
end

items = Item.where(group_id: group_id)
puts "#{items.length} items"
for item in items
  puts "##{item.id}: #{item.subject}"
end
 