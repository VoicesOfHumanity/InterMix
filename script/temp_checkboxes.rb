require File.dirname(__FILE__)+'/cron_helper'

# Make sure those with (old) checkboxes checked have the corresponding community tags
# Make sure those with community tags have checkboxes checked that match

old_checkboxes = ['indigenous','other_minority','veteran','interfaith','refugee']

# Go through all users
puts "Going through users"
participants = Participant.all
for participant in participants
  # Go through the old checkboxes
  for cb in old_checkboxes
    if participant.send(cb)
      puts "#{participant.email}: #{cb}"
      # They have the checkbox checked. Add the tag, if they don't have it
      cb = 'minority' if cb == 'other_minority'
      cb = 'refugees' if cb == 'refugee'
      cb = 'veterans' if cb == 'veteran'
      participant.tag_list.add(cb)
      participant.save
    end
  end 
end

