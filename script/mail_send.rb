# encoding: utf-8

#-- mail_send.rb --- send daily/weekly batch mail
#-- Right now we'll assume we only run this once per day. Later we might have a preferential hour set in each user's settings, and run it hourly.

require File.dirname(__FILE__)+'/cron_helper'

if Time.now.wday == 5
  #-- If it is Friday
  is_weekly = true
else
  is_weekly = false 
end  

participants = Participant.where("status='active' and no_email=0 and (private_email='daily' or private_email='weekly' or system_email='daily' or system_email='weekly' or forum_email='daily' or forum_email='weekly')").order(:id)
puts "#{participants.length} participants"

for p in participants
  puts "#{p.id}: #{p.name}: private:#{p.private_email} system:#{p.system_email} forum:#{p.forum_email}"
  
  tdaily = ''
  tweekly = ''
  
  #-- Private Messages
  
  
  #-- System Messages
  
  
  #-- Forum Items
  
  
  
  
  
  if tdaily != ''
  
    subject = "InterMix Daily Digest"
  
    email = ItemMailer.digest(subject, tdaily, p.email_address_with_name, cdata)
  
    begin
      logger.info("mail_send delivering daily email to #{p.id}:#{p.name}")
      email.deliver
      message_id = email.message_id
    rescue
      logger.info("mail_send problem delivering daily email to #{p.id}:#{p.name}")
    end
  
  end

  if is_weekly and tweekly != ''
  
    subject = "InterMix Weekly Digest"
  
    email = ItemMailer.digest(subject, tweekly, p.email_address_with_name, cdata)
  
    begin
      logger.info("mail_send delivering weekly email to #{p.id}:#{p.name}")
      email.deliver
      message_id = email.message_id
    rescue
      logger.info("mail_send problem delivering weekly email to #{p.id}:#{p.name}")
    end
  
  end
  
  
  
end