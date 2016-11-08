# encoding: utf-8

#-- mail_send.rb --- send daily/weekly batch mail
#-- Right now we'll assume we only run this once per day. Later we might have a preferential hour set in each user's settings, and run it hourly.
#-- We'll send everything for the last day/week, up until last midnight. So, this should run a bit after midnight.

require File.dirname(__FILE__)+'/cron_helper'
require 'optparse'

participant_id = 0
do_weekly = false
testonly = false
whichday = ''

# testing: ruby mail_send.rb -p 6 -d 2013-11-10 -w 1 
opts = OptionParser.new
opts.on("-pARG","--participant=ARG",Integer) {|val| participant_id = val}
opts.on("-wARG","--weekly=ARG",Integer) {|val| do_weekly = true}
opts.on("-dARG","--day=ARG",String) {|val| whichday = val}
opts.on("-tARG","--test=ARG",Integer) {|val| testonly = true}
opts.parse(ARGV)

if whichday != ''
  #-- If a day is given, it should be the day on which (a little after midnight) the report is run for the day before
  now = Time.parse(whichday).gmtime
else
  now = Time.now.gmtime
end    
puts "Now: #{now.strftime("%Y-%m-%d %H:%M:%S")}"

if now.wday == 4 or do_weekly
#if now.wday == 6
  #-- If it is Saturday
  is_weekly = true
  puts "Today is the day to run weeklies"
else
  is_weekly = false 
end  

if do_weekly
  puts "Forcing weekly mailing, regardless of settings"
end  

wstart = now.midnight - 1.week
dstart = now.midnight - 1.day
pend = now.midnight - 1.second

if is_weekly or do_weekly
  puts "Week: #{wstart} - #{pend}"
end  
puts "Day: #{dstart} - #{pend}"

if participant_id.to_i > 0
  participants = Participant.where(:id=>participant_id)
else
  #participants = Participant.where("status='active' and no_email=0 and (private_email='daily' or private_email='weekly' or system_email='daily' or system_email='weekly' or subgroup_email='daily' or subgroup_email='weekly' or group_email='daily' or group_email='weekly' or forum_email='daily' or forum_email='weekly')").order(:id)
  participants = Participant.where("status='active' and no_email=0 and (private_email='daily' or private_email='weekly' or system_email='daily' or system_email='weekly' or mycom_email='daily' or mycom_email='weekly' or othercom_email='daily' or othercom_email='weekly')").order(:id)
end
puts "#{participants.length} participants"

numdailysent = 0
numdailyerror = 0
numweeklysent = 0
numweeklyerror = 0

#-- Go through all users that have any setting of daily or weekly mail, and who hasn't blocked mail altogether
for p in participants
  puts "#{p.id}: #{p.name}: private:#{p.private_email} system:#{p.system_email} mycom:#{p.mycom_email} othercom:#{p.othercom_email} tags:#{p.tag_list}"

  participant = p

  tdaily = ''
  tweekly = ''
  
  messages = []
  
  if p.system_email == 'daily' or ((p.system_email == 'weekly' or do_weekly) and is_weekly)
    #-- System Messages
    pstart = ((p.system_email == 'weekly' or do_weekly) and is_weekly) ? wstart : dstart
    messages += Message.where(:to_participant_id => p.id, :from_participant_id => 0).where(do_weekly ? "email_sent=0" : "").where("created_at>='#{pstart.strftime("%Y-%m-%d %H:%M:%S")}'").order(:id)
    puts "  " + messages.length.to_s + ' ' + (((p.system_email == 'weekly' or do_weekly) and is_weekly) ? "weekly" : "daily") + " system messages"
  end
  
  if p.private_email == 'daily' or ((p.private_email == 'weekly' or do_weekly) and is_weekly)
    #-- Private Messages
    pstart = ((p.private_email == 'weekly' or do_weekly) and is_weekly) ? wstart : dstart
    messages += Message.where(:to_participant_id => p.id).where(do_weekly ? "email_sent=0" : "").where("from_participant_id>0").where("created_at>='#{pstart.strftime("%Y-%m-%d %H:%M:%S")}'").order(:id)
    puts "  " + messages.length.to_s + ' ' + (((p.private_email == 'weekly' or do_weekly) and is_weekly) ? "weekly" : "daily") + " personal messages"
  end
  
  #-- First do their messages
  for message in messages
    itext = ""
    
    puts "    #{message.created_at.strftime("%Y-%m-%d %H:%M")}: #{message.subject}"
    itext = ""
    itext += "<h3><a href=\"http://#{BASEDOMAIN}/messages?auth_token=#{p.authentication_token}\">#{message.subject}</a></h3>"
    itext += "<div>"
    itext += message.message
    itext += "</div>"
    
    itext += "<p>"
    if message.from_participant_id.to_i > 0
		  itext += "from <a href=\"http://#{BASEDOMAIN}/participant/#{message.from_participant_id}/wall?auth_token=#{p.authentication_token}\">#{message.sender ? message.sender.name : message.from_participant_id}</a>"
	  else
	    itext += "System Message"
	  end  
		
		itext += " " + message.created_at.strftime("%Y-%m-%d %H:%M")
    itext += "</p>"
    itext += "<hr>"
    
    if (p.system_email == 'weekly' or do_weekly) and is_weekly and message.from_participant_id == 0
      #-- A system message for a weekly batch
      tweekly += itext    
    elsif (p.private_email == 'weekly' or do_weekly) and is_weekly and message.from_participant_id > 0
      #-- A private message for a weekly batch
      tweekly += itext
    else
      tdaily += itext
    end  
    message.email_sent 
    if not message.email_sent
      message.email_sent = true
      message.email_sent_at = Time.now
    end
    if not message.sent
      message.sent = true
      message.sent_at = Time.now
    end
    message.save
  end
  
  #-- Now dealing with the mycom_email or othercom_email settings
  
  need_daily = ( p.mycom_email == 'daily' or p.othercom_email == 'daily' )
  need_weekly = (( p.mycom_email == 'weekly' or p.othercom_email == 'weekly' or do_weekly) and is_weekly)
    
  if need_daily or need_weekly
    #-- Get the forum Items
    
    #-- Do we start a week ago, or a day ago?
    pstart = need_weekly ? wstart : dstart
    
    #-- We want sort by descending regressed value, using total interest
    items, itemsproc, extras = Item.list_and_results(0,0,0,0,{},{},false,'*value*',p,true,p.id,pstart,pend)
    
    #-- Note that we might have gotten more items than we actually need
    
    if need_daily and need_weekly
      ptext = "daily/weekly"
    elsif need_weekly
      ptext = "weekly"
    else
      ptext = "daily"
    end  
    will_items = items.length    
    puts "  #{will_items} #{ptext} items"
    did_items = 0
    
    user_dialogs = {}
    
    for item in items
      
      puts "    ##{item.id}: #{item.created_at}: #{item.subject} : #{item.tag_list}" if testonly
      
      #-- Is it an item we need, or do we skip it?
      in_week = true
      in_day = (item.created_at > dstart)

      # Does the user have any tags found in the message tags for that message?
      hasmessmatch = ( p.tag_list.length > 0 and p.tag_list.all?{|t| item.tag_list.include?(t) } )
      
      # Does the user have any tags found in the community tags of the author of that message
      hascommatch = ( p.tag_list.length > 0 and p.tag_list.all?{|t| item.participant.tag_list } )

      send_it = false
      is_mycom = (hasmessmatch and hascommatch)
      
      if is_mycom and p.mycom_email == 'daily' and in_day
        puts "    community match. user set for daily my community mail" if testonly
        send_it = true
      elsif is_mycom and p.mycom_email == 'weekly' and in_week
        puts "    community match. user set for weekly my community mail" if testonly
        send_it = true
      elsif not is_mycom and p.othercom_email == 'daily' and in_day
        puts "    no community match. user set for daily other community mail" if testonly
        send_it = true
      elsif not is_mycom and p.othercom_email == 'weekly' and in_week
        puts "    no community match. user set for weekly other community mail" if testonly
        send_it = true
      end   
   
      if not send_it
        puts "    no setting to send this" if testonly
        next
      end
      
      did_items += 1
      
      domain = "voh.#{ROOTDOMAIN}"
      
      group_domain = (item.group and item.group.shortname.to_s != '') ? "#{item.group.shortname}.#{ROOTDOMAIN}" : ROOTDOMAIN

      puts "    #{item.created_at.strftime("%Y-%m-%d %H:%M")}: #{item.subject} | domain: #{domain}"
      
      itext = ""
      #itext += "<h3><a href=\"http://#{domain}/items/#{item.id}/view?auth_token=#{p.authentication_token}\">#{item.subject}</a></h3>"
      itext += "<h3><a href=\"http://#{domain}/items/#{item.id}/thread?auth_token=#{p.authentication_token}&amp;exp_item_id=#{item.id}#item_#{item.id}\">#{item.subject}</a></h3>"
      itext += "<div>"
      itext += item.html_with_auth(p)
      itext += "</div>"
      
      itext += "<p>by "

  		if false and item.dialog and item.dialog.current_period.to_i > 0 and not item.dialog.settings_with_period["names_visible_voting"]  and item.is_first_in_thread
  		  itext += "[name withheld during decision period]"
  		elsif false and item.dialog and item.dialog.current_period.to_i == 0 and not item.dialog.settings_with_period["names_visible_general"] and item.is_first_in_thread
  		  itext += "[name withheld for this discussion]"  		
  		elsif item.dialog and not item.dialog.settings_with_period["profiles_visible"]
  		  itext += item.participant ? item.participant.name : item.posted_by
  		else
  		  itext += "<a href=\"http://#{domain}/participant/#{item.posted_by}/wall?auth_token=#{p.authentication_token}\">#{item.participant ? item.participant.name : item.posted_by}</a>"
  		end
  		itext += " " + item.created_at.strftime("%Y-%m-%d %H:%M")
  		itext += " <a href=\"http://#{domain}/items/#{item.id}/view?auth_token=#{p.authentication_token}\" title=\"permalink\">#</a>"
      
      itext += " <a href=\"http://#{domain}/items/#{item.id}/view?auth_token=#{p.authentication_token}#reply\">One Click reply</a>"
      
      itext += "</p>"
      itext += "<hr>"
      
      if is_mycom and p.mycom_email == 'weekly' and is_weekly
        tweekly += itext
      elsif not is_mycom and p.othercom_email == 'weekly' and is_weekly
        tweekly += itext
      else
        tdaily += itext
      end  
      
    end
    
    if will_items > 0 and did_items == 0
      puts "  #{did_items} #{ptext} items were processed. #{will_items} were expected"
    end   
    
  end
  
  cdata = {}
  cdata['recipient'] = p      
  
  #-- Send any daily digest for this person. We do that every day, if there's something to send.
  if tdaily != ''
  
    #subject = "InterMix Daily Digest, #{dstart.strftime("%Y-%m-%d")}"
    subject = "[voicesofhumanity] Daily Digest, #{dstart.strftime("%Y-%b-%d")}"
  
    email = ItemMailer.digest(subject, tdaily, p.email_address_with_name, cdata)
  
    if testonly
      puts "  here we would have sent the email, if it weren't a test"
    else  
      begin
        Rails.logger.info("mail_send delivering daily email to #{p.id}:#{p.name}")
        email.deliver
        message_id = email.message_id
        puts "  daily e-mail sent: #{email.message_id}"
        numdailysent += 1
      rescue Exception => e
        puts "  daily e-mail delivery problem"
        Rails.logger.info("mail_send problem delivering daily email to #{p.id}:#{p.name}: #{e}")
        numdailyerror += 1
      end
    end
  
  end

  #-- Send any weekly digest for this person, if it is the day we run weeklies, and there's something to send
  if is_weekly and tweekly != ''
  
    #subject = "InterMix Weekly Digest, #{wstart.strftime("%Y-%m-%d")} - #{pend.strftime("%Y-%m-%d")}"
    subject = "[voicesofhumanity] Weekly Digest, #{wstart.strftime("%Y-%b-%d")} - #{pend.strftime("%Y-%b-%d")}"
  
    email = ItemMailer.digest(subject, tweekly, p.email_address_with_name, cdata)
  
    if testonly
      puts "  here we would have sent the email, if it weren't a test"
    else  
      begin
        Rails.logger.info("mail_send delivering weekly email to #{p.id}:#{p.name}")
        email.deliver
        message_id = email.message_id
        puts "  weekly e-mail sent: #{email.message_id}"
        numweeklysent += 1
      rescue Exception => e
        puts "  weekly e-mail delivery problem"
        Rails.logger.info("mail_send problem delivering weekly email to #{p.id}:#{p.name}: #{e}")
        numweeklyerror += 1
      end
    end  
  
  end
  
end

puts "#{numdailysent} daily messages sent. #{numdailyerror} errors"
puts "#{numweeklysent} weekly messages sent. #{numweeklyerror} errors"
