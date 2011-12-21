# encoding: utf-8

# Import members and messages for old Global Assembly Dialog

require File.dirname(__FILE__)+'/cron_helper'
require 'csv'


# First read in the xref file, which keeps track of what is responses
xref = {}
x = 0
reader = CSV.open("/tmp/xref.csv",'r')
header = reader.shift
puts header.inspect
reader.each do |xarr|
  #Item1ID,Item2ID,relationType,value,Root,Level,OrderBy
  #0,1,,,1,0,0
  #0,2,,,2,0,0
  x += 1
  next if x == 1
  #puts xarr.join(", ")
  item1 = xarr[0].to_i
  item2 = xarr[1].to_i
  root = xarr[4].to_i
  level = xarr[5].to_i
  orderby = xarr[6].to_i
  xref[item2] = {'reply_to'=>item1,'first_in_thread'=>root,'level'=>level,'orderby'=>orderby}
end

old_to_new = {}
new_to_old = {}

x = 0
#IO.foreach("/Users/ffunch/_websites/intermix/data/IntermixCVSfiles/messages.csv") do |line|
#reader = CSV.open("/Users/ffunch/_websites/intermix/data/IntermixCVSfiles/messages.csv",'r')
reader = CSV.open("/tmp/messages.csv",'r')
header = reader.shift
puts header.inspect
reader.each do |xarr|
  #message_id,date_added,user_id,round_id,section_id,message_title,message_text,isroundwinner,interest,approval,rank,moderation_status_id,moderated_by,moderation_date,issectionsurvivor,distinctintrate,distinctapprate,version_id,author_tag,subject_tag,dialog_tag,round_tag,network_tag,inForum,type,group_tag,SubmitForum,forum_display_type
  #5,7/7/2007,86,1,1,Enough!,"<IMG src=""http://farm2.static.flickr.com/1260/731154861_3ae3df38a8.jpg?v=0"">",0,0,0,2.7,,,,1,,,1,,,2,,,Y,C,,0,N
  x += 1
  next if x == 1
  #next if not xarr
  #line = line.force_encoding("ISO-8859-1").encode("UTF-8").strip
  #puts line
  #xarr = line.split(',')
  #puts xarr.join(", ")
  message_id = xarr[0].to_i
  date_added = xarr[1].split('/')
  if date_added.length == 3
    created_at = Time.local(date_added[2].to_i,date_added[0].to_i,date_added[1].to_i)
  else
    created_at = Time.now
  end
  old_user_id = xarr[2].to_i
  round_id = xarr[3].to_i
  section_id = xarr[4].to_i
  subject = xarr[5].to_s.strip
  html_content = xarr[6].to_s.strip
  isroundwinner = xarr[7]
  interest = xarr[8]
  approval = xarr[9]
  rank = xarr[10]
  moderation_status_id = xarr[11]
  moderated_by = xarr[12]
  moderation_date = xarr[13]
  issectionsurvivor = xarr[14]
  distinctintrate = xarr[15]
  distinctapprate = xarr[16]
  version_id = xarr[17]
  author_tag = xarr[18]
  subject_tag = xarr[19]
  dialog_tag = xarr[20]
  round_tag = xarr[21]
  network_tag = xarr[22]
  inForum = xarr[23].to_s
  type = xarr[24]
  group_tag = xarr[25]
  submit_forum = xarr[26]
  forum_display_type = xarr[27]
  
  puts "  mess:#{message_id}  ver:#{version_id} subj:#{subject}"
  
  item = Item.find_by_old_message_id(message_id)
  
  if item
    puts "    already have it"
  elsif inForum != 'Y'
    puts "    not in forum"  
  else  
    
    participant = Participant.find_by_old_user_id(old_user_id)
    
    item = Item.new
    item.dialog_id = 1
    item.posted_by = participant.id if participant
    item.subject = subject
    item.html_content = Sanitize.clean(html_content, Sanitize::Config::RELAXED)
    item.short_content = item.html_content.gsub(/<\/?[^>]*>/, "").strip[0,140]
    item.interest = interest
    item.approval = approval
    item.old_message_id = message_id
    item.created_at = created_at
    item.posted_to_forum = true
    if xref[message_id]
      if xref[message_id]['reply_to'] > 0
        #-- It's a reply to another message
        old_reply_to = xref[message_id]['reply_to']
        old_first_in_thread = xref[message_id]['first_in_thread']
        if old_to_new[old_reply_to]
          #-- We have the one it answers
          puts "    reply to old:#{old_reply_to} = new:#{old_to_new[old_reply_to]}"
          item.is_first_in_thread = false
          item.reply_to = old_to_new[old_reply_to]
          if old_to_new[old_first_in_thread]
            item.first_in_thread = old_to_new[old_first_in_thread]
          else
            item.first_in_thread = old_to_new[old_reply_to]
          end  
        else
          puts "    reply to a message we don't have (#{old_reply_to})"
          item.is_first_in_thread = true          
        end
      else
        item.is_first_in_thread = true
      end
    else  
      item.is_first_in_thread = true
    end  
    
    if not item.save  
      puts "  couldn't save"
    else
      item.create_xml
      item.save
      if item.is_first_in_thread
        item.first_in_thread = item.id
      end  
      old_to_new[message_id] = item.id
      new_to_old[item.id] = message_id
      item.save
    end
    
  end
  
end