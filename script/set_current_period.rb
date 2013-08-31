# encoding: utf-8

# Set the current period for discussions, based on dates

require File.dirname(__FILE__)+'/cron_helper'

today = Time.now.strftime("%Y-%m-%d")
today = Time.now
today = Date.today
puts "Today: #{today}"

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
      else
        #-- This is not a current period, but it is set as current period  
        if dialog.current_period == period.id
          dialog.current_period = 0
          dialog.posting_open = true
          dialog.voting_open = true
          dialog.save!
          print " - - removed from CURRENT\n"          
        end
      end
      if dialog.current_period == period.id
        #-- If this is the current period
        #-- Set or unset open posting, if necessary
        if  today >= period.startdate and today <= period.endposting
          if dialog.posting_open
            print " - - posting was already open\n"          
          else  
            dialog.posting_open = true
            dialog.save!
            print " - - posting set to OPEN\n"          
          end
        else
          if not dialog.posting_open
            print " - - posting was already closed\n"          
          else  
            dialog.posting_open = false
            dialog.save!
            print " - - posting set to CLOSED\n"          
          end
        end
        #-- Set or unset open rating, as necessary
        if  today >= period.startdate and today <= period.endrating
          if dialog.voting_open
            print " - - voting was already open\n"          
          else  
            dialog.voting_open = true
            dialog.save!
            print " - - voting set to OPEN\n"          
          end
        else
          if not dialog.voting_open
            print " - - voting was already closed\n"          
          else  
            dialog.voting_open = false
            dialog.save!
            print " - - voting set to CLOSED\n"          
          end
        end
      end  
    end
  end

end