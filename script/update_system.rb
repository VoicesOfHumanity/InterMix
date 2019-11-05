require File.dirname(__FILE__)+'/cron_helper'

# This is run regularly, like every hour, to update current moon phase and together/apart, so that it doesn't have to be looked up everywhere

sys = SysDatum.order(:id).first
if sys
  puts "System record id: #{sys.id}"
else
  puts "Creating a system record"
  sys = SysDatum.create()
end

now = Time.now.utc
nowdate = now.strftime("%Y-%m-%d")
nowtime = now.strftime("%H:%M")

puts "Now: date:#{nowdate} Time:#{nowtime}" 

# Find the currently active period
moon = Moon.where("mdate<='#{nowdate}'").order(mdate: :desc).first
if moon
  mdate = moon.mdate
  mtime = moon.mtime
  new_or_full = moon.new_or_full
  puts "Found active moon record #{moon.id} : #{mdate} : #{mtime} : #{new_or_full}"
  
  datetimestr = moon.mdate.strftime("%Y-%m-%d") + 'T' + moon.mtime + ':00'
  puts "To string: #{datetimestr}"

  sys.moon_startdate = DateTime.parse(datetimestr)
  puts "Start datetime: #{sys.moon_startdate}"
  
  sys.cur_moon_id = moon.id
  
  sys.moon_new_or_full = new_or_full
  if new_or_full == 'full'
    sys.together_apart = 'together'
  else
    sys.together_apart = 'apart'
  end
  puts "Together/Apart: #{sys.together_apart}"
end

# Find the next period coming up
moon = Moon.where("mdate>'#{nowdate}'").order(mdate: :asc).first
if moon
  mdate = moon.mdate
  mtime = moon.mtime
  new_or_full = moon.new_or_full
  puts "Found next moon record #{moon.id} : #{mdate} : #{mtime} : #{new_or_full}"

  datetimestr = moon.mdate.strftime("%Y-%m-%d") + 'T' + moon.mtime + ':00'
  puts "To string: #{datetimestr}"

  moon_enddate = DateTime.parse(datetimestr)
  puts "Start datetime: #{sys.moon_startdate}"
else
  puts "Found no next moon record"
  # User either start + 14 days, or, if that is in the past, the end of today
  moon_enddate = sys.moon_startdate + 14.days
  if moon_enddate < now
    moon_enddate = now.end_of_day
  end
  puts "Calculating #{moon_enddate}"
end

sys.moon_enddate = moon_enddate
puts "End datetime: #{sys.moon_enddate}"

sys.save!
puts "Updated system record"

puts "Updating all conversations"
conversations = Conversation.all
for conversation in conversations
  if conversation.together_apart != sys.together_apart
    puts "Updating #{conversation.shortname} #{conversation.together_apart}->#{sys.together_apart}"
    conversation.together_apart = sys.together_apart
    conversation.save
  end
end



