# encoding: utf-8

#-- mail_send.rb --- send daily/weekly batch mail
#-- Right now we'll assume we only run this once per day. Later we might have a preferential hour set in each user's settings, and run it hourly.
#-- We'll send everything for the last day/week, up until last midnight. So, this should run a bit after midnight.

require File.dirname(__FILE__)+'/cron_helper'

wstart = Time.now.midnight - 1.week
dstart = Time.now.midnight - 1.day
pend = Time.now.midnight - 1.second

if Time.now.wday == 3
#if Time.now.wday == 6
  #-- If it is Saturday
  is_weekly = true
else
  is_weekly = false 
end  

participants = Participant.where("status='active' and no_email=0 and (private_email='daily' or private_email='weekly' or system_email='daily' or system_email='weekly' or forum_email='daily' or forum_email='weekly')").order(:id)
puts "#{participants.length} participants"

for p in participants
  puts "#{p.id}: #{p.name}: private:#{p.private_email} system:#{p.system_email} forum:#{p.forum_email}"

  pstart = (p.forum_email == 'weekly' and is_weekly) ? wstart : dstart
  
  tdaily = ''
  tweekly = ''
  
  if p.private_email == 'daily' or (p.private_email == 'weekly' and is_weekly)
    #-- Private Messages
  end
  
  if p.system_email == 'daily' or (p.system_email == 'weekly' and is_weekly)
    #-- System Messages
  end
  
  if p.forum_email == 'daily' or (p.forum_email == 'weekly' and is_weekly)
    #-- Forum Items
    
    ptext = (p.forum_email == 'weekly' and is_weekly) ? "weekly" : "daily"
    
    #-- We want sort by descending regressed value, using total interest
    items, itemsproc = Item.list_and_results(0,0,0,0,{},{},false,'*value*',p.id,true,p.id,pstart,pend)
    
    puts "  #{ptext}: #{items.length} items"
    
    for item in items
      puts "    #{item.created_at.strftime("%Y-%m-%d %H:%M")}: #{item.subject}"
      itext = ""
      itext += "<h3><a href=\"http://#{BASEDOMAIN}/items/#{item.id}/view?auth_token=#{p.authentication_token}\">#{item.subject}</a></h3>"
      itext += "<div>"
      itext += item.html_content
      itext += "</div>"
      
      itext += "<p>by "

  		if item.dialog and item.dialog.current_period.to_i > 0 and not item.dialog.settings_with_period["names_visible_voting"]
  		  itext += "[name withheld during focus period]"
  		elsif item.dialog and item.dialog.current_period.to_i == 0 and not item.dialog.settings_with_period["names_visible_general"]
  		  itext += "[name withheld for this discussion]"  		
  		elsif item.dialog and not item.dialog.settings_with_period["profiles_visible"]
  		  itext += item.participant ? item.participant.name : item.posted_by
  		else
  		  itext += "<a href=\"http://#{BASEDOMAIN}/participant/#{item.posted_by}/wall?auth_token=#{p.authentication_token}\">#{item.participant ? item.participant.name : item.posted_by}</a>"
  		end
  		itext += " " + item.created_at.strftime("%Y-%m-%d %H:%M")
  		itext += " <a href=\"http://#{BASEDOMAIN}/items/#{item.id}/view?auth_token=#{p.authentication_token}\" title=\"permalink\">#</a>"
  		
  		itext += " Discussion: <a href=\"http://#{BASEDOMAIN}/dialogs/#{item.dialog_id}/forum?auth_token=#{p.authentication_token}\">#{item.dialog.name}</a>" if item.dialog
  		itext += " Focus Period: <a href=\"http://#{BASEDOMAIN}/dialogs/#{item.dialog_id}/forum?period_id=#{item.period_id}&auth_token=#{p.authentication_token}\">#{item.period.name}</a>" if item.period  		
  		itext += " Group: <a href=\"http://#{BASEDOMAIN}/groups/#{item.group_id}/forum?auth_token=#{p.authentication_token}\">#{item.group.name}</a>" if item.group
      itext += "</p>"
      itext += "<hr>"
      
      if p.forum_email == 'weekly' and is_weekly
        tweekly += itext
      else
        tdaily += itext
      end  
      
    end  
    
  end
  
  cdata = {}
  cdata['recipient'] = p      
  
  if tdaily != ''
  
    subject = "InterMix Daily Digest, #{pstart.strftime("%Y-%m-%d")}"
  
    email = ItemMailer.digest(subject, tdaily, p.email_address_with_name, cdata)
  
    begin
      Rails.logger.info("mail_send delivering daily email to #{p.id}:#{p.name}")
      email.deliver
      message_id = email.message_id
      puts "    e-mail sent: #{email.message_id}"
    rescue
      puts "    e-mail delivery problem"
      Rails.logger.info("mail_send problem delivering daily email to #{p.id}:#{p.name}")
    end
  
  end

  if is_weekly and tweekly != ''
  
    subject = "InterMix Weekly Digest, #{pstart.strftime("%Y-%m-%d")} - #{pend.strftime("%Y-%m-%d")}"
  
    email = ItemMailer.digest(subject, tweekly, p.email_address_with_name, cdata)
  
    begin
      Rails.logger.info("mail_send delivering weekly email to #{p.id}:#{p.name}")
      email.deliver
      message_id = email.message_id
      puts "    e-mail sent: #{email.message_id}"
    rescue
      puts "    e-mail delivery problem"
      Rails.logger.info("mail_send problem delivering weekly email to #{p.id}:#{p.name}")
    end
  
  end
  
  
  
end