# encoding: utf-8

require File.dirname(__FILE__)+'/cron_helper'

# Following model in http://railspikes.com/2007/6/1/rails-email-processing
# Maybe should run monit like they suggest?

require 'net/pop'

if RAILS_ENV == "test"
  SLEEP_TIME = 10
else
  SLEEP_TIME = 60
end

puts "Starting Mail Fetcher"

#loop do
  pop = Net::POP3.new("mail.intermix.org")
  pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE) if false
  pop.start("intermix", "im45tyu")
  unless pop.mails.empty?
    pop.each_mail do |m|
      ReceiveMailer.receive(m.pop)
      m.delete
    end
  end
  pop.finish
  
#  sleep(SLEEP_TIME)
#end

