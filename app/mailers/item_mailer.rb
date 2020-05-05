# encoding: utf-8

class ItemMailer < ActionMailer::Base
  #-- For sending forum items to those who have a right to see them, and are configured to receive them
  
  default :from => SYSTEM_SENDER
  
  def item(subject,message,email,cdata={})
    #-- A forum item
    @message = message
    @cdata = cdata if cdata   
    headers["InterMix-ID"] = "i#{cdata['item'].id}" if cdata['item']
    mail(
      to: email,
      subject: (subject ? subject : "InterMix forum posting")
    )
    mail.header['X-PM-Message-Stream'] = 'broadcast-stream'
  end  

  def group_item(subject,message,email,cdata={})
    #-- A group forum item
    @message = message
    @cdata = cdata  
    #if @cdata['group'] and @cdata['group'].has_mail_list and @cdata['group'].shortname.to_s != ''
    #  #@from = "#{@cdata['group'].shortname}-list@#{ROOTDOMAIN}"
    #  @from = "#{@cdata['group'].shortname}-#{@cdata['item'].id}-list@#{ROOTDOMAIN}"
    #else
    #  @from = "noreply@#{ROOTDOMAIN}"      
    #end  
    @from = SYSTEM_SENDER
    headers["InterMix-ID"] = "i#{cdata['item'].id}" if cdata['item']
    #headers["Reply-To"] = @from
    mail(
      :reply_to => @from,
      :to => email,
      :subject => subject
    )
    mail.header['X-PM-Message-Stream'] = 'broadcast-stream'
  end  
  
  def digest(subject,message,email,cdata={})
    #-- Daily or weekly digests of items, personal or system messages
    @message = message
    @cdata = cdata if cdata   
    mail(
      :to => email,
      :subject => (subject ? subject : "InterMix Message Digest")
    )
    mail.header['X-PM-Message-Stream'] = 'broadcast-stream'
  end

  def moon(subject,message,email,cdata={})
    #-- New moon message to everybody
    @message = message
    @cdata = cdata if cdata   
    mail(
      :to => email,
      :subject => (subject ? subject : "[voicesofhumanity] New Moon")
    )
    mail.header['X-PM-Message-Stream'] = 'broadcast-stream'
  end

end