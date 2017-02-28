require File.dirname(__FILE__)+'/cron_helper'

# Convert some community tag names to new names

conv = {
  'nonukes' => 'nuclear_disarm'
}

# Go through all users
puts "Going through users"
participants = Participant.all
for p in participants
  changed = false
  for tag in p.tag_list
    to = conv[tag]
    if to
      puts "#{p.id}:#{p.email}: Convert #{tag} to #{to}"
      p.tag_list.remove(tag)
      p.tag_list.add(to)
      changed = true
    end
  end
  if changed
    p.save
    puts "#{p.id}:#{p.email}: updated"
  end
end


