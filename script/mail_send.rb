# encoding: utf-8

#-- mail_send.rb --- send daily/weekly batch mail
#-- Right now we'll assume we only run this once per day. Later we might have a preferential hour set in each user's settings, and run it hourly.
#-- We'll send everything for the last day/week, up until last midnight. So, this should run a bit after midnight.

require File.dirname(__FILE__)+'/cron_helper'
require 'optparse'

participant_id = 0
do_weekly = false
testonly = false

# testing: ruby mail_send.rb -p 6 -w 1
opts = OptionParser.new
opts.on("-pARG","--participant=ARG",Integer) {|val| participant_id = val}
opts.on("-wARG","--weekly=ARG",Integer) {|val| do_weekly = true}
opts.on("-tARG","--test=ARG",Integer) {|val| testonly = true}
opts.parse(ARGV)

if Time.now.wday == 4 or do_weekly
#if Time.now.wday == 6
  #-- If it is Saturday
  is_weekly = true
  puts "Today is the day to run weeklies"
else
  is_weekly = false 
end  

if do_weekly
  puts "Forcing weekly mailing, regardless of settings"
end  

wstart = Time.now.midnight - 1.week
dstart = Time.now.midnight - 1.day
pend = Time.now.midnight - 1.second

if is_weekly or do_weekly
  puts "Week: #{wstart} - #{pend}"
end  
puts "Day: #{dstart} - #{pend}"

if participant_id.to_i > 0
  participants = Participant.where(:id=>participant_id)
else
  participants = Participant.where("status='active' and no_email=0 and (private_email='daily' or private_email='weekly' or system_email='daily' or system_email='weekly' or group_email='daily' or group_email='weekly' or forum_email='daily' or forum_email='weekly')").order(:id)
end
puts "#{participants.length} participants"

numdailysent = 0
numdailyerror = 0
numweeklysent = 0
numweeklyerror = 0

#-- Go through all users that have any setting of daily or weekly mail, and who hasn't blocked mail altogether
for p in participants
  puts "#{p.id}: #{p.name}: private:#{p.private_email} system:#{p.system_email} forum:#{p.forum_email}"

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
      message.email_sent 
      message.email_sent_at = Time.now
    end
    if not message.sent
      message.sent 
      message.sent_at = Time.now
    end
    message.save
  end
  
  #-- Group items have a different setting from Discussion items
  #-- Discussion items are the forum_email setting. Group items are the group_email setting.
  
  need_daily = ( p.group_email == 'daily' or p.forum_email == 'daily' )
  need_weekly = ((p.group_email == 'weekly' or p.forum_email == 'weekly' or do_weekly) and is_weekly)
    
  if need_daily or need_weekly
    #-- Get the forum Items
    
    #-- Do we start a week ago, or a day ago?
    pstart = need_weekly ? wstart : dstart
    
    #-- We want sort by descending regressed value, using total interest
    items, itemsproc = Item.list_and_results(0,0,0,0,{},{},false,'*value*',p.id,true,p.id,pstart,pend)
    
    #-- Note that we might have gotten more items than we actually need
    
    if need_daily and need_weekly
      ptext = "daily/weekly"
    elsif need_weekly
      ptext = "weekly"
    else
      ptext = "daily"
    end      
    puts "  #{items.length} #{ptext} items"
    
    user_dialogs = {}
    
    for item in items
      
      #-- Is it an item we need, or do we skip it?
      in_week = true
      in_day = (item.created_at > dstart)
      in_group = (item.group_id.to_i > 0)
      in_dialog = (item.dialog_id.to_i > 0)
      
      if in_dialog
        if p.forum_email == 'daily' and in_day
        elsif p.forum_email == 'weekly' and in_week
        else
          next
        end     
      elsif in_group
        if p.group_email == 'daily' and in_day
        elsif p.group_email == 'weekly' and in_week
        else
          next
        end     
      else
        next
      end    
      
      #-- Figure out the best domain to use, with discussion and group
      if item.dialog
        #-- If it is in a discussion, this person possibly represents another group
        group_prefix = ''
        if user_dialogs[item.dialog_id]
          group_prefix = user_dialogs[item.dialog_id]['group_prefix']
        else
          user_dialogs[item.dialog_id] = {'group_prefix'=>''}
          group_participant = GroupParticipant.where(:participant_id => p.id, :group_id => item.group_id).first
          if group_participant
            #-- They're a member of the group, so that's the one to use
            group_prefix = item.group.shortname if item.group
            user_dialogs[item.dialog_id]['group_prefix'] = group_prefix
          else
            for g in item.dialog.active_groups
              group_participant = GroupParticipant.where(:participant_id => p.id,:group_id => g.id).first
              if group_participant and g.shortname.to_s != ''
                group_prefix = g.shortname
                user_dialogs[item.dialog_id]['group_prefix'] = group_prefix
                break
              end
            end
          end    
        end
        if item.dialog.shortname.to_s != '' and group_prefix != ''
          domain = "#{item.dialog.shortname}.#{group_prefix}.#{ROOTDOMAIN}"
        elsif group_prefix != ''
          domain = "#{group_prefix}.#{ROOTDOMAIN}"
        elsif item.dialog.shortname.to_s != ''
          domain = "#{item.dialog.shortname}.#{ROOTDOMAIN}"
        else
          domain = BASEDOMAIN
        end      
      elsif item.group and item.group.shortname.to_s != ''
        #-- If it is posted in a group, that's where we'll go, whether they're a member of it or not
        domain = "#{item.group.shortname}.#{ROOTDOMAIN}"
      else
        domain = BASEDOMAIN
      end 
      
      group_domain = (item.group and item.group.shortname.to_s != '') ? "#{item.group.shortname}.#{ROOTDOMAIN}" : ROOTDOMAIN

      puts "    #{item.created_at.strftime("%Y-%m-%d %H:%M")}: #{item.subject} | domain: #{domain}"
      
      itext = ""
      #itext += "<h3><a href=\"http://#{domain}/items/#{item.id}/view?auth_token=#{p.authentication_token}\">#{item.subject}</a></h3>"
      itext += "<h3><a href=\"http://#{domain}/items/#{item.id}/thread?auth_token=#{p.authentication_token}&#item_#{item.id}\">#{item.subject}</a></h3>"
      itext += "<div>"
      itext += item.html_with_auth(p)
      itext += "</div>"
      
      itext += "<p>by "

  		if item.dialog and item.dialog.current_period.to_i > 0 and not item.dialog.settings_with_period["names_visible_voting"]  and item.is_first_in_thread
  		  itext += "[name withheld during decision period]"
  		elsif item.dialog and item.dialog.current_period.to_i == 0 and not item.dialog.settings_with_period["names_visible_general"] and item.is_first_in_thread
  		  itext += "[name withheld for this discussion]"  		
  		elsif item.dialog and not item.dialog.settings_with_period["profiles_visible"]
  		  itext += item.participant ? item.participant.name : item.posted_by
  		else
  		  itext += "<a href=\"http://#{domain}/participant/#{item.posted_by}/wall?auth_token=#{p.authentication_token}\">#{item.participant ? item.participant.name : item.posted_by}</a>"
  		end
  		itext += " " + item.created_at.strftime("%Y-%m-%d %H:%M")
  		itext += " <a href=\"http://#{domain}/items/#{item.id}/view?auth_token=#{p.authentication_token}\" title=\"permalink\">#</a>"
  		
  		itext += " Discussion: <a href=\"http://#{domain}/dialogs/#{item.dialog_id}/forum?auth_token=#{p.authentication_token}\">#{item.dialog.name}</a>" if item.dialog
  		itext += " Decision Period: <a href=\"http://#{domain}/dialogs/#{item.dialog_id}/forum?period_id=#{item.period_id}&auth_token=#{p.authentication_token}\">#{item.period.name}</a>" if item.period  		
  		itext += " Group: <a href=\"http://#{group_domain}/groups/#{item.group_id}/forum?auth_token=#{p.authentication_token}\">#{item.group.name}</a>" if item.group
      itext += "</p>"
      itext += "<hr>"
      
      if in_dialog and p.forum_email == 'weekly' and is_weekly
        tweekly += itext
      elsif in_group and p.group_email == 'weekly' and is_weekly
        tweekly += itext
      else
        tdaily += itext
      end  
      
    end  
    
  end
  
  cdata = {}
  cdata['recipient'] = p      
  
  #-- Send any daily digest for this person. We do that every day, if there's something to send.
  if tdaily != ''
  
    subject = "InterMix Daily Digest, #{dstart.strftime("%Y-%m-%d")}"
  
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
  
    subject = "InterMix Weekly Digest, #{wstart.strftime("%Y-%m-%d")} - #{pend.strftime("%Y-%m-%d")}"
  
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
