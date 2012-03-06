# encoding: utf-8

# Set the current period for discussions, based on dates

require File.dirname(__FILE__)+'/cron_helper'

today = Time.now

dialogs = Dialog.order("id")

for dialog in dialogs
  print "#{dialog.id}: #{dialog.name}\n"
  
  periods = Period.where("dialog_id=#{dialog.id}").order("id")
  
  for period in periods
    if period.startdate.to_s != '' and period.endposting.to_s != '' and period.endrating.to_s != ''
      print " - #{period.startdate} - #{period.endposting}/#{period.endrating}: #{period.name}\n"
      if  today >= period.startdate and (today <= period.endposting or today <= period.endrating)
        if dialog.current_period == period.id
          print " - - was already current\n"          
        else  
          dialog.current_period = period.id
          dialog.save!
          print " - - set to CURRENT\n"          
        end
      end
      #if  today >= period.startdate and today <= period.endrating
      #  if dialog.voting_open
      #    print " - - voting was already open\n"          
      #  else  
      #    dialog.voting_open = true
      #    dialog.save!
      #    print " - - voting set to OPEN\n"          
      #  end
      #end
    end
  end

end