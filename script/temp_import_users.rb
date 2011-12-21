# encoding: utf-8

# Import members from old Global Assembly Dialog

require File.dirname(__FILE__)+'/cron_helper'

# the file is in ISO-8859-1
#type_id,user_id,user_guid,date_added,username,password,firstname,lastname,email,title,address1,address2,city,state,zipcode,phone,status,hub_id,country,bioregion,faithTradition
#1,1,{46BF3677-227D-40DF-89DB-1DBD52D7A6A4},12/1/2005,rogereaton@groupdialog.org,8778881869,Roger,Eaton,rogereaton@groupdialog.org,,,,,,,415 933 0153,Accept,1,,,

x = 0
#IO.foreach("/Users/ffunch/_websites/intermix/data/IntermixCVSfiles/user.csv") do |line|
IO.foreach("/tmp/user.csv") do |line|
  x += 1
  next if x == 1
  line = line.force_encoding("ISO-8859-1").encode("UTF-8").strip
  xarr = line.split(',')
  type_id = xarr[0].to_i
  user_id = xarr[1].to_i
  guid = xarr[2]
  date_added = xarr[3].split('/')
  if date_added.length == 3
    created_at = Time.local(date_added[2].to_i,date_added[0].to_i,date_added[1].to_i)
  else
    created_at = Time.now
  end
  username = xarr[4]
  password = xarr[5]
  first_name = xarr[6]
  last_name = xarr[7]
  email = xarr[8]
  title = xarr[9]
  address1 = xarr[10]
  address2 = xarr[11]
  city = xarr[12]
  state = xarr[13]
  zip = xarr[14]
  phone = xarr[15]
  status = xarr[16]
  hub_id = xarr[17].to_i
  country = xarr[18]
  bioregion = xarr[19]
  faithtradition = xarr[20]
  
  puts "#{x}: #{first_name}, #{last_name}, #{email}"
  
  if email.to_s == ''
    next
  end
  
  participant = Participant.find_by_email(email)

  if participant
    puts "  already have it"
  else  
    participant = Participant.new
    participant.first_name = first_name
    participant.last_name = last_name
    participant.email = email
    participant.title = title
    participant.password = password if password.to_s != ''
    participant.address1 = address1
    participant.address2 = address2
    participant.city = city
    participant.state_code = state.upcase if state.to_s != ''
    participant.admin1uniq = "US.#{state.upcase}" if state.to_s != ''
    participant.zip = zip
    participant.phone = phone
    participant.country_code = 'US' if state.to_s != ''
    participant.forum_email = 'never'
    participant.group_email = 'never'
    participant.private_email = 'never'  
    participant.old_user_id = user_id
    participant.sysadmin = true if type_id == 1
    participant.status = 'inactive'
    participant.created_at = created_at
    if not participant.save  
      puts "  couldn't save"
      next
    end  
  end

  dp = DialogParticipant.find_by_dialog_id_and_participant_id(1,participant.id)
  DialogParticipant.create(:dialog_id=>1,:participant_id=>participant.id) if not dp
    
  if type_id == 2  
    da = DialogAdmin.find_by_dialog_id_and_participant_id(1,participant.id)
    if not da
      da = DialogAdmin.new(:dialog_id=>1,:participant_id=>participant.id) 
      da.moderator = true if type_id == 3
      da.save!
    end
  end
  
end