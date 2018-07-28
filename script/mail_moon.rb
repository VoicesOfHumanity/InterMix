#-- mail_moon.rb --- send winners when it's a new moon
#-- Run this every day. Will decide if it is full moon, based on the hardcoded ranges in the settings
#-- Should be on the next day, after the new moon.

# ruby mail_moon.rb -d2017-06-24 -p6
# ruby mail_moon.rb -d2017-05-26 -p6

require File.dirname(__FILE__)+'/cron_helper'
require 'optparse'

current_participant = nil
current_participant_id = 0
participant_id = 0
runday = ''
testonly = false

# testing: ruby mail_send.rb -p 6 -d "2013-11-10 15:45" -w 1 
opts = OptionParser.new
opts.on("-pARG","--participant=ARG",Integer) {|val| participant_id = val}
opts.on("-dARG","--day=ARG",String) {|val| runday = val}        # Include time
opts.on("-tARG","--test=ARG",Integer) {|val| testonly = true}
opts.parse(ARGV)

if testonly
  puts "Test Mode"
end

if runday != ''
  #-- If a day is given, it should be the day/time on which the mailing is expected to go out
  now = Time.parse(runday)
else
  now = Time.now.utc
end 
puts "Running this on utc time #{now.strftime("%Y-%m-%d %H:%M")}"


do_it = false

# Did we pass any time for new or full moon, which hasn't been sent yet?

nowdate = now.strftime("%Y-%m-%d")
nowtime = now.strftime("%H:%M")
@moon = Moon.where("mdate<='#{nowdate}'").order(mdate: :desc).first
if @moon and @moon.mailing_sent
  puts "Day #{@moon.mdate.strftime("%Y-%m-%d")} mailing was already sent"
elsif @moon and @moon.mdate.strftime("%Y-%m-%d") < nowdate and @moon.mdate < (nowdate - 2)
  puts "Day #{@moon.mdate.strftime("%Y-%m-%d")} has already passed, but it was too long ago"
elsif @moon and @moon.mdate.strftime("%Y-%m-%d") < nowdate
  # The time doesn't matter, the day is already passed
  puts "Day #{@moon.mdate.strftime("%Y-%m-%d")} has just passed"
  do_it = true
elsif @moon
  # It's the right day. Have we passed the hour yet?
  puts "It's the right day"
  if nowtime >= @moon.mtime
    puts "and the right time"
    do_it = true
  else
    puts "It is not yet the right time"
  end
else
  puts "There is no moon that hasn't been processed"
end

if do_it
  puts "OK, let's do it"
else
  puts "stopping"
  exit
end

puts "It's a #{@moon.new_or_full} moon"

crit = {}
@data = {}

crit[:from] = 'mail'

# Get the period
@datefrom = @moon.previous_date
@dateto = @moon.mdate

crit[:datefromuse] = @datefrom
crit[:datefromto] = @dateto
puts "Using period #{@datefrom} - #{@dateto}" 

#-- Whichever day (today or yesterday) is the new/full moon, use that

today = @moon.mdate
todaystr = today.strftime("%Y-%m-%d")
whichday = todaystr
puts "Today string: #{todaystr}"
todayfull = today.strftime("%Y-%b-%d")

# NB: Just for testing
#crit[:datefromuse] = '2012-04-05'
#crit[:datefromto] = '2017-06-01'    

if @moon.new_or_full == 'full'
  # must have #nvaction
  crit[:nvaction] = true
else
  # exclude #nvaction
  crit[:nvaction] = false
end

ages = MetamapNode.where(metamap_id: 5).order(:sortorder)
genders = MetamapNode.where(metamap_id: 3).order(:sortorder)

gender_pos = {207=>"Men's",208=>"Women's"}
gender_single = {207=>"Men",208=>"Women"}

puts("crit: #{crit.inspect}")

#-- Get the winners for the period
puts("Calculating results...")

# two genders, three ages, and voice of humanity
# total
crit[:gender] = 0
crit[:age] = 0
name = "Voice of Humanity-as-One"
item = nil
iproc = nil        
items,ratings,@title = Item.get_items(crit,current_participant)
puts "gender:all age:all items:#{items.length}"
@itemsproc,@extras = Item.get_itemsproc(items,ratings,current_participant_id)
@sortby = '*value*'
@items = Item.get_sorted(items,@itemsproc,@sortby,false)
#puts "extras:#{@extras}"
if @items.length > 0 and ratings.length > 0
  exp = ""
  #exp = "@items[0].id:#{@items[0].id} @itemsproc[items[0].id]['value']:#{@itemsproc[items[0].id]['value']}"
  #exp = @itemsproc[items[0].id].inspect
  if @itemsproc.has_key?(@items[0].id) and @itemsproc[@items[0].id]['value'] > 0
    item = @items[0]
    iproc = @itemsproc[item.id]
    #exp = iproc.inspect
    #exp = "#{(@items[0]).id}/#{item.id}"
  end
end
@data['all'] = {name: name, item: item, iproc: iproc, itemcount: @items.length, ratingcount: ratings.length, extras: @extras, image:'humanity.png'}

for gender_rec in genders
  gender_id = gender_rec.id
  gender_name = gender_rec.name_as_group
  code = "#{gender_id}"
  name = "#{gender_name}"
  if not gender_rec.sumcat
    item = nil
    iproc = nil
    exp = ""
    
    crit[:gender] = gender_id
    crit[:age] = 0
    items,ratings,title = Item.get_items(crit,current_participant)
    @itemsproc,@extras = Item.get_itemsproc(items,ratings,current_participant_id)
    @sortby = '*value*'
    @items = Item.get_sorted(items,@itemsproc,@sortby,false)
    puts "gender:#{name} age:all items:#{@items.length}"
    if @items.length > 0 and ratings.length > 0
      if @itemsproc.has_key?(@items[0].id) and @itemsproc[@items[0].id]['value'] > 0
        item = @items[0]
        iproc = @itemsproc[item.id]
      end
    end
       
    if gender_id==207
      image = 'men.png'
    elsif gender_id==208
      image = 'women.png'
    else
      image = 'humanity.png'  
    end
        
    @data[code] = {name: name, item: item, iproc: iproc, itemcount: @items.length, ratingcount: ratings.length, extras: @extras, image: image}
  end
end
for age_rec in ages
  age_id = age_rec.id
  age_name = age_rec.name_as_group
  code = "#{age_id}"
  name = "#{age_name}"
  if not age_rec.sumcat
    item = nil
    iproc = nil
    
    crit[:age] = age_id
    crit[:gender] = 0
    items,ratings,title = Item.get_items(crit,current_participant)
    @itemsproc,@extras = Item.get_itemsproc(items,ratings,current_participant_id)
    @sortby = '*value*'
    @items = Item.get_sorted(items,@itemsproc,@sortby,false)
    puts "gender:all age:#{name} items:#{@items.length}"
    if @items.length > 0 and ratings.length > 0
      if @itemsproc.has_key?(@items[0].id) and @itemsproc[@items[0].id]['value'] > 0
        item = @items[0]
        iproc = @itemsproc[item.id]
      end
    end
    
    if age_id==405
      image = 'youth.png'
    elsif age_id==406
      image = 'experience.png'
    elsif age_id==407
      image = 'wisdom.png'
    else
      image = 'humanity.png'  
    end
    
    @data[code] = {name: name, item: item, iproc: iproc, itemcount: @items.length, ratingcount: ratings.length, extras: @extras, image: image}
  end
end

#-- Go through the results
puts("Results:")
@data.each do |name,info|
  heading = info[:name ]
  puts(heading)
    
  if info[:item]
    puts("  " + info[:item].id.to_s + ": " + info[:item].subject + " (value:#{info[:iproc]['value']},raters:#{info[:iproc]['num_raters']})")
      #-- render :partial => "items/item", :locals => { :item => info[:item], :itemproc=>info[:iproc], :is_reply=>false, :from=>'result', :odd_or_even=>1, :top=>0, :exp_item_id=>0 } 

  else
    puts("[no winner]")
  end

end

#if testonly
#  puts "Test Mode. Not going through participants"
#  exit
#end

if participant_id.to_i > 0
  participants = Participant.where(:id=>participant_id)
else
  participants = Participant.where("status='active' and no_email=0").order(:id)
end
puts "Going through #{participants.length} participants"

domain = "voh.#{ROOTDOMAIN}"

numsent = 0
numerror = 0

#-- Go through all users who haven't blocked mail altogether
for p in participants
  puts "#{p.id}: #{p.name}: private:#{p.private_email} system:#{p.system_email} mycom:#{p.mycom_email} othercom:#{p.othercom_email} tags:#{p.tag_list}"

  participant = p
  
  etext = ""  
  etext += "<p>" + @moon.top_text + "</p>" if @moon.top_text.to_s != ''
  etext += "<hr/>"

  @data.each do |name,info|
    heading = info[:name ]
    puts(heading)
    
    if info[:item]
      item = info[:item]
      image = info[:image]
      
        puts "    #{item.created_at.strftime("%Y-%m-%d %H:%M")}: #{item.subject}"
      
        link_to = "https://#{domain}/items/#{item.id}/thread?auth_token=#{p.authentication_token}&amp;exp_item_id=#{item.id}"
        if not item.is_first_in_thread
          link_to += "#item_#{item.id}"
        end
      
        itext = ""
        #itext += "<h3><a href=\"http://#{domain}/items/#{item.id}/view?auth_token=#{p.authentication_token}\">#{item.subject}</a></h3>"
        
        itext += "<img src=\"https://voh.intermix.org/images/#{image}\" align=\"left\" style=\"float:left;padding-right:10px;width:100px\" /><h1>#{heading}</h1>"
        
        itext += "<h3><a href=\"#{link_to}\">#{item.subject}</a></h3>"
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
        itext += "<hr style=\"clear:left\">"
      
        etext += itext

    else
      puts("[no winner]")
    end

  end
  
  etext += "<p>" + @moon.bottom_text + "</p>" if @moon.bottom_text.to_s != ''
  
  cdata = {}
  cdata['recipient'] = p      
  
  subject = "[voicesofhumanity] #{@moon.new_or_full.capitalize} Moon, #{todayfull}"

  email = ItemMailer.moon(subject, etext, p.email_address_with_name, cdata)

  if testonly
    puts "  here we would have sent the email, if it weren't a test"
  else  
    begin
      Rails.logger.info("mail_send delivering daily email to #{p.id}:#{p.name}")
      email.deliver
      message_id = email.message_id
      puts "  moon e-mail sent: #{email.message_id}"
      numsent += 1
    rescue Exception => e
      puts "  moon e-mail delivery problem"
      Rails.logger.info("mail_moon problem delivering daily email to #{p.id}:#{p.name}: #{e}")
      numerror += 1
    end
  end


end

if not testonly
  puts "Moon set as mailing having been sent"
  @moon.mailing_sent = true
  @moon.save
else
  puts "Not setting moon as sent, because we're only testing"
end

puts "#{numsent} daily messages sent. #{numerror} errors"
