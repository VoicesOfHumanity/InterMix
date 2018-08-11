require File.dirname(__FILE__)+'/cron_helper'

comtags = Participant.tag_counts_on(:tags).collect{|t| t.name}

for comtag in comtags
  com = Community.where(tagname: comtag).first
  if not com
    puts "#{comtag} doesn't exist"
    com = Community.create(tagname: comtag)
    com.save
  else
    puts "#{comtag} exists"
    puts "  major" if com.major
    puts "  more" if com.more
    puts "  ungoals" if com.ungoals
    puts "  sustdev" if com.sustdev
    # See who has it
    members = Participant.where(status: 'active', no_email: false).tagged_with(comtag)
    puts "  #{members.length} members"
    # admins
    admins = CommunityAdmin.where(community_id: com.id)
    puts "  #{admins.length} moderators:"
    for admin in admins
      puts "    #{admin.participant_id}: #{admin.participant.email}"
    end
  end
end
