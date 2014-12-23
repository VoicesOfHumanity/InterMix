#-- get_fb_photos.rb ---- grab FB photos for users that have a FB account, and who don't already have a picture

require File.dirname(__FILE__)+'/cron_helper'

participants = Participant.where("fb_uid!=''")
for participant in participants
  fb_uid = participant.fb_uid.to_i
  if fb_uid > 0
    puts "User #{participant.email} has FB ID #{fb_uid}"
    if participant.picture.exists?
      puts " - already has a picture"
    else
      url = "https://graph.facebook.com/#{fb_uid}/picture?type=large"
      puts " - downloading #{url}"
    
      participant.picture = URI.parse(url)
      participant.save!
      
      if participant.picture.exists?
        puts " - now has a picture"
      end
    end
  end
end