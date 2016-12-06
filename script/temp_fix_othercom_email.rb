# Change the othercom_email for all users to be whatever

require File.dirname(__FILE__)+'/cron_helper'

participants = Participant.where(nil)

for participant in participants
  if participant.othercom_email != participant.forum_email
    puts "#{participant.email} #{participant.othercom_email} -> #{participant.forum_email}"
    participant.othercom_email = participant.forum_email
    participant.save
  end
end