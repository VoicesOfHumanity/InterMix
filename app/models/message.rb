class Message < ActiveRecord::Base
  belongs_to :sender, :class_name => 'Participant', :foreign_key => :from_participant_id
  belongs_to :recipient, :class_name => 'Participant', :foreign_key => :to_participant_id
  belongs_to :group, :foreign_key => :to_group_id

  serialize :received_json
  
  def emailit
    #-- E-mail this message. We assume that it already has been saved and has an ID
    
    recipient = Participant.find_by_id(self.to_participant_id) if self.to_participant_id.to_i > 0
    @group ||= Group.find_by_id(self.to_group_id) if self.to_group_id.to_i > 0
    
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

    @group ||= Group.find_by_id(self.group_id) if self.group_id.to_i > 0
    
    # Make sure we have an authentication token for them to log in with
    # http://yekmer.posterous.com/single-access-token-using-devise
    recipient.ensure_authentication_token!
    
    cdata = {}

    cdata['recipient'] = recipient
    cdata['group'] = @group if @group
    
    #@cdata['attachments'] = @attachments
    
    cdata['message'] = self
    
    if @group and @group.shortname.to_s != ''
      msubject = "[#{@group.shortname}] #{self.subject}"
    else
      msubject = self.subject
    end  

    domain = (@group and @group.shortname.to_s!='') ? "#{@group.shortname}.#{ROOTDOMAIN}" : BASEDOMAIN

    cdata['participant'] = recipient
    cdata['domain'] = domain
    cdata['groupforumlink'] = "<a href=\"https://#{domain}/groups/#{@group.id}/forum?auth_token=#{recipient.authentication_token}\">https://#{domain}/groups/#{@group.id}/forum?auth_token=#{recipient.authentication_token}</a>" if @group
    cdata['group_logo'] = "http://#{BASEDOMAIN}#{@group.logo.url}" if @group and @group.logo.exists?
    cdata['editsettingslink'] = "https://#{domain}/me/profile/edit?auth_token=#{recipient.authentication_token}#settings"
    
    #dialogs = OpenStruct.new
    dialogs = {}
    if @group
      if @group.dialogs
        for dialog in @group.dialogs
          if dialog.shortname.to_s != ''
            d = {}
            d['shortname'] = dialog.shortname
            d['name'] = dialog.name
            d['description'] = dialog.description
            d['shortdesc'] = dialog.shortdesc
            d['forumlink'] = "<a href=\"https://#{dialog.shortname}.#{domain}/dialogs/#{dialog.id}/slider?auth_token=#{recipient.authentication_token}\">https://#{dialog.shortname}.#{domain}/dialogs/#{dialog.id}/slider?auth_token=#{recipient.authentication_token}</a>"
            d['logo'] = "#{BASEDOMAIN}#{dialog.logo.url}" if dialog.logo.exists?        
            d['dialog_logo'] = "#{BASEDOMAIN}#{dialog.logo.url}" if dialog.logo.exists?        
            dialogs[dialog.shortname] = d
            #dialogs.send("#{dialog.shortname}=", d)
            cdata[dialog.shortname] = d
          end
        end
      end
    end  
    cdata['discussion'] = dialogs
    
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
    elsif to_group_id.to_i > 0
      #-- A group message 
      email = MessageMailer.group(msubject, sendmessage, recipient.email_address_with_name, cdata)
      self.mail_template = 'message_group'
    else    
      email = MessageMailer.individual(msubject, sendmessage, recipient.email_address_with_name, cdata)
      self.mail_template = 'message_individual'
    end
    
    logger.info("Message#emailit delivering email to #{recipient.id}:#{recipient.name}")
    begin
      email.deliver
      self.message_id = email.message_id
      self.sent = true
      self.sent_at = Time.now 
      self.email_sent = true
      self.email_sent_at = Time.now
    rescue Exception => e
      self.sent = false
      logger.info("Message#emailit FAILED delivering email to #{recipient.id}:#{recipient.name}: #{e}")
    end

    save!
    
  end  
  
  
  
end
