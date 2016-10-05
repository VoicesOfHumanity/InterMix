require File.dirname(__FILE__)+'/cron_helper'
require 'optparse'

# Turn a specified group into some specified tags
# We will get the group ID and the tag(s)
# The tags will be applied as community @tags to the members, and message #tags to the messages

group_id = 0
tags =  ''
do_interfaith = false

opts = OptionParser.new
opts.on("-gARG","--group=ARG",Integer) {|val| group_id = val.to_i}
opts.on("-tARG","--tags=ARG",String) {|val| tags = val.to_s}
opts.on("-iARG","--interfaith=ARG",String) {|val| do_interfaith = true}
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

tags_a = []
if tags != ''
  tags_a = tags.split(',')
  puts "Tags:"
  for tag in tags_a
    puts "  #{tag}"
  end
else
  puts "No tags"
end

if do_interfaith
  puts "Set interfaith"
end

group_participants = GroupParticipant.where(group_id: group_id).includes(:participant)
puts "#{group_participants.length} members"
for group_participant in group_participants
  participant = group_participant.participant
  participant.tag_list.remove('-i1')
  for tag in tags_a
    participant.tag_list.add(tag)
  end
  if do_interfaith
    participant.interfaith = true
  end
  participant.tag_list.add('indigenous') if participant.indigenous
  participant.tag_list.add('minority') if participant.other_minority
  participant.tag_list.add('veteran') if participant.veteran
  participant.tag_list.add('interfaith') if participant.interfaith
  participant.tag_list.add('refugee') if participant.refugee
  participant.save!
  puts "##{participant.id}: #{participant.name}: #{participant.tag_list}"
end

items = Item.where(group_id: group_id)
puts "#{items.length} items"
for item in items
  item.tag_list.remove('-i1')
  for tag in tags_a
    item.tag_list.add(tag)
  end
  item.save
  puts "##{item.id}: #{item.subject}: #{item.tag_list}"
end
 