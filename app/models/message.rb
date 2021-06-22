class Message < ActiveRecord::Base
  belongs_to :sender, optional: true, class_name: 'Participant', foreign_key: :from_participant_id
  belongs_to :recipient, optional: true, class_name: 'Participant', foreign_key: :to_participant_id
  belongs_to :remote_sender, optional: true, class_name: 'RemoteActor', foreign_key: :from_remote_actor_id
  belongs_to :remote_recipient, optional: true, class_name: 'RemoteActor', foreign_key: :to_remote_actor_id

  serialize :received_json
  
  def plain
    #-- Return a plain version of message, without html, and without any beginning @ff2590@intermix.cr8.com ... etc
    txt = message.gsub(/<\/?[^>]*>/, "")
    first = txt.split.first
    if first[0] == '@'
      txt = txt.split[1..-1].join(' ')
    end
    return txt
  end
  
  def emailit
    #-- E-mail this message. We assume that it already has been saved and has an ID
    
    recipient = Participant.find_by_id(self.to_participant_id) if self.to_participant_id.to_i > 0
    
    if recipient.no_email
      logger.info("Message#emailit #{recipient.id}:#{recipient.name} is blocking all email, so skipping")
      return        
    #elsif @group and not recipient.group_email=='instant'
    #  logger.info("Message#emailit #{recipient.id}:#{recipient.name} is not set for instant group mail, so skipping")
    #  return
    elsif recipient.email.to_s == ''
      logger.info("Message#emailit #{recipient.id}:#{recipient.name} has no e-mail, so skipping")
      return
    end      

    # Make sure we have an authentication token for them to log in with
    # http://yekmer.posterous.com/single-access-token-using-devise
    recipient.ensure_authentication_token!
    
    cdata = {}

    cdata['recipient'] = recipient
    
    #@cdata['attachments'] = @attachments
    
    cdata['message'] = self
    
    msubject = self.subject

    domain = (@group and @group.shortname.to_s!='') ? "#{@group.shortname}.#{ROOTDOMAIN}" : BASEDOMAIN

    cdata['participant'] = recipient
    cdata['domain'] = domain
    cdata['editsettingslink'] = "https://#{domain}/me/profile/edit?auth_token=#{recipient.authentication_token}#settings"
    
    #cdata['exp'] = cdata['newdis'].inspect
    
    #-- Expand any macros    
    sendmessage = Liquid::Template.parse(self.message).render(cdata)
      
    if self.mail_template.to_s == 'message_system'  
      email = MessageMailer.system(msubject, sendmessage, recipient.email_address_with_name, cdata)
    elsif self.mail_template.to_s == 'message_import'  
      email = MessageMailer.import(msubject, sendmessage, recipient.email_address_with_name, cdata)
    elsif self.mail_template.to_s == 'message_contacts'  
      email = MessageMailer.contacts(msubject, sendmessage, recipient.email_address_with_name, cdata)
    elsif self.mail_template.to_s == 'message_group'  
      email = MessageMailer.group(msubject, sendmessage, recipient.email_address_with_name, cdata)
    elsif self.mail_template.to_s == 'message_individual'  
      email = MessageMailer.individual(msubject, sendmessage, recipient.email_address_with_name, cdata)
    elsif from_participant_id.to_i == 0
      #-- Must be a system message
      email = MessageMailer.contacts(msubject, sendmessage, recipient.email_address_with_name, cdata)
      self.mail_template = 'message_contacts'
    else    
      email = MessageMailer.individual(msubject, sendmessage, recipient.email_address_with_name, cdata)
      self.mail_template = 'message_individual'
    end
    
    logger.info("Message#emailit delivering email to #{recipient.id}:#{recipient.name}")
    begin
      email.deliver
      self.message_id = email.message_id
      if not self.sent
        self.sent = true
        self.sent_at = Time.now 
      end
      self.email_sent = true
      self.email_sent_at = Time.now
    rescue Exception => e
      self.sent = false
      logger.info("Message#emailit FAILED delivering email to #{recipient.id}:#{recipient.name}: #{e}")
    end

    save!
    
  end  
  
  
  
end
