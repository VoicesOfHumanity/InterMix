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
  end
end

