# encoding: utf-8

class ItemMailer < ActionMailer::Base
  #-- For sending forum items to those who have a right to see them, and are configured to receive them
  
  default :from => "do-not-reply@intermix.org"
  
  def item(subject,message,email,cdata={})
    #-- A forum item
    @message = message
    @cdata = cdata if cdata   
    headers["InterMix-ID"] = "i#{cdata['item'].id}" if cdata['item']
    mail(
      :to => email,
      :subject => (subject ? subject : "InterMix forum posting")
    )
  end  

  def group_item(subject,message,email,cdata={})
    #-- A group forum item
    @message = message
    @cdata = cdata  
    if @cdata['group'] and @cdata['group'].has_mail_list and @cdata['group'].shortname.to_s != ''
      @from = "#{@cdata['group'].shortname}-list@intermix.cr8.com"
    else
      @from = "do-not-reply@intermix.org"      
    end  
    headers["InterMix-ID"] = "i#{cdata['item'].id}" if cdata['item']
    headers["Reply-To"] = "#{@cdata['group'].shortname}-#{@cdata['item'].id}-list@intermix.cr8.com"
    mail(
      :from => @from,
      :to => email,
      :subject => subject
    )
  end  

end