class Message < ActiveRecord::Base
  belongs_to :sender, :class_name => 'Participant', :foreign_key => :from_participant_id
  belongs_to :recipient, :class_name => 'Participant', :foreign_key => :to_participant_id
  belongs_to :group, :foreign_key => :to_group_id
  
  def emailit
    #-- E-mail this message. We assume that it already has been saved and has an ID
    
    recipient = Participant.find_by_id(self.to_participant_id) if self.to_participant_id.to_i > 0
    @group ||= Group.find_by_id(self.to_group_id) if self.to_group_id.to_i > 0
    
    if recipient.no_email
      logger.info("Message#emailit #{recipient.id}:#{recipient.name} is blocking all email, so skipping")
      return        
    elsif @group and not recipient.group_email=='instant'
      logger.info("Message#emailit #{recipient.id}:#{recipient.name} is not set for instant group mail, so skipping")
      return
    elsif recipient.email.to_s == ''
      logger.info("Message#emailit #{recipient.id}:#{recipient.name} has no e-mail, so skipping")
      return
    end      
    
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
      
    if from_participant_id.to_i == 0
      #-- Must be a system message
      email = MessageMailer.contacts(msubject, self.message, recipient.email_address_with_name, cdata)
    elsif to_group_id.to_i > 0
      #-- A group messages  
      email = MessageMailer.group(msubject, self.message, recipient.email_address_with_name, cdata)
    else    
      email = MessageMailer.individual(msubject, self.message, recipient.email_address_with_name, cdata)
    end
    
    logger.info("Message#emailit delivering email to #{recipient.id}:#{recipient.name}")
    begin
      email.deliver
      self.message_id = email.message_id
      self.sent = true
      self.sent_at = Time.now 
    rescue
      self.sent = false
      logger.info("Message#emailit FAILED delivering email to #{recipient.id}:#{recipient.name}")
    end

    save!
    
  end  
  
  
  
end
