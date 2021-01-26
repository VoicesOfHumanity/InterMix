require File.dirname(__FILE__)+'/cron_helper'

# Create unique account ids for users that don't have it, for ActivePub, etc.


for p in Participant.all

  account_uniq = p.generate_account_uniq
  
  if BASEDOMAIN.include? ":"
    account_uniq_full = "#{account_uniq}@#{ROOTDOMAIN}"
  else
    # Preferable
    account_uniq_full = "#{account_uniq}@#{BASEDOMAIN}"
  end
  
  puts "#{p.id} : #{p.name} : #{account_uniq} : #{account_uniq_full}"
  
  if p.account_uniq != account_uniq or p.account_uniq_full != account_uniq_full
    p.account_uniq = account_uniq
    p.account_uniq_full = account_uniq_full
    p.save!
    puts "  - updated"
  end

end