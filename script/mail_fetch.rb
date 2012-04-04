# encoding: utf-8

require File.dirname(__FILE__)+'/cron_helper'

# Following model in http://railspikes.com/2007/6/1/rails-email-processing
# Maybe should run monit like they suggest?

require 'net/pop'

#if RAILS_ENV == "test"
#  SLEEP_TIME = 10
#else
#  SLEEP_TIME = 60
#end

puts "Starting Mail Fetcher to #{MAILDOMAIN}/intermix"

#loop do
  #pop = Net::POP3.new("mail.intermix.org")
  pop = Net::POP3.new(MAILDOMAIN)
  pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE)
  pop.start("intermix", "im45tyu")
  if pop.mails.empty?
    puts "- no mail"
  else
    puts "- accessing mail"
    x = 1
    pop.each_mail do |m|
      puts "- #{x}"
      ReceiveMailer.receive(m.pop)
      puts "- processed. now deleting"
      m.delete
      x += 1
    end
  end
  puts '- finishing'
  pop.finish
  
#  sleep(SLEEP_TIME)
#end

