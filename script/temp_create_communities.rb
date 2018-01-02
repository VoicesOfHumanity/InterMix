require File.dirname(__FILE__)+'/cron_helper'

# Item.tag_counts_on(:tags).collect{|t| t.name}
# Item.tags

puts "Comtags from participants *****************"

# comtags = Paticipant.tags
comtags = Participant.tag_counts_on(:tags).collect{|t| t.name}

for comtag in comtags
  com = Community.where(tagname: comtag).first
  if not com
    puts "creating #{comtag}"
    com = Community.create(tagname: comtag)
    com.save
  else
    puts "#{comtag} exists"  
  end
end

puts "Comtags from configuration ******************"

DEFAULT_COMMUNITIES.each do |comtag,description|
  com = Community.where(tagname: comtag).first
  if not com
    puts "creating #{comtag}"
    com = Community.create(tagname: comtag)
    com.save
  else
    puts "#{comtag} exists"  
    if com.description.to_s == ''
      puts "updating description for #{comtag}"
      com.description = description
      com.save
    end
    if com.fullname.to_s == ''
      puts "updating fullname for #{com.description}"
      com.fullname = com.description
      com.save
    end
  end
end

GLOBAL_COMMUNITIES.each do |comtag,description|
  com = Community.where(tagname: comtag).first
  if com
    puts "setting #{comtag} to major"
    com.major = true
    com.save
  end
end

UNGOAL_COMMUNITIES.each do |comtag,description|
  com = Community.where(tagname: comtag).first
  if com
    puts "setting #{comtag} to ungoals"
    com.ungoals = true
    com.save
  end
end

SUSTDEV_COMMUNITIES.each do |comtag,description|
  com = Community.where(tagname: comtag).first
  if com
    puts "setting #{comtag} to sustdev"
    com.sustdev = true
    com.save
  end
end

BOLD_COMMUNITIES.each do |comtag,description|
  com = Community.where(tagname: comtag).first
  if com
    puts "setting #{comtag} to bold"
    com.bold = true
    com.save
  end
end

