# encoding: utf-8

class SystemMailer < ActionMailer::Base
  #-- Various messages the system sends to users, which aren't stored in messages
  
  default :from => SYSTEM_SENDER
  
  def generic(from=nil,to,subject,message,cdata)
    #-- For messages about follows, friends, etc
    @message = message
    @cdata = cdata if cdata   
    mail(
      :reply_to => from,
      :to => to,
      :subject => (subject ? subject : "InterMix Contacts")
    )
  end  
  
  
end
