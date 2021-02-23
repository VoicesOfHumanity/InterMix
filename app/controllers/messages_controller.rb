class MessagesController < ApplicationController
  
  layout "front"
  before_action :authenticate_user_from_token!
  before_action :authenticate_participant!, :check_group_and_dialog
  
  def index
    @section = 'messages'
    @psection = 'mail'
    @from = params[:from] || ''
    
    @sortby = params[:sortby] || "messages.id desc"
    @perscr = params[:perscr].to_i || 25
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    
    @inout = params[:inout] || 'in'
    @newmess = (params[:newmess].to_i == 1) 
    
    @messages = Message.where(nil)
    @messages = @messages.where(:to_group_id => params[:to_group_id]) if params[:to_group_id].to_i > 0
      
    if @inout == 'conv'
      @participant_id = ( params[:participant_id] || current_participant.id ).to_i
      @participant = Participant.find(@participant_id)
      @messages = @messages.where("(from_participant_id=#{current_participant.id} and to_participant_id=#{@participant_id}) or (from_participant_id=#{@participant_id} and to_participant_id=#{current_participant.id})")        
      @messages = @messages.includes([:sender,:recipient])
    elsif @inout == 'out'  
      @messages = @messages.where(:from_participant_id => current_participant.id) 
      @messages = @messages.includes([:group,:recipient])
    else
      @messages = @messages.where(:to_participant_id => current_participant.id)
      @messages = @messages.includes([:group,:sender])
    end
      
    @messages = @messages.order(@sortby)
    @messages = @messages.paginate :page=>@page, :per_page => @per_page    
    update_last_url
  end
  
  def list
    index
    if not params.include?(:inout)
      redirect_to "/messages"
    else  
      render :partial=>'list', :layout=>false  
    end
  end  
  
  def conversation
    # Could have been in the people controller
    @section = 'messages'
    @psection = 'messages'
    @from = 'messages'
    @participant_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.find(@participant_id)

    @inout = params[:inout] || 'conv'

    @sortby = params[:sortby] || "messages.id desc"
    @perscr = params[:perscr].to_i || 25
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1

    @messages = Message.where(nil)
    
    @messages = @messages.where("(from_participant_id=#{current_participant.id} and to_participant_id=#{@participant_id}) or (from_participant_id=#{@participant_id} and to_participant_id=#{current_participant.id})")
    
    @messages = @messages.order(@sortby)
    @messages = @messages.paginate :page=>@page, :per_page => @per_page    
    update_last_url
  end

  def new
    #-- New message
    @psection = 'mail'
    @from = params[:from] || ''
    @response_to_id = params[:response_to_id].to_i
    @to_participant_id = params[:to_participant_id].to_i
    @message = Message.new
    @message.to_participant_id = 0
    @to_participant_name = '???'
    if @response_to_id > 0
      @message.response_to_id = @response_to_id
      @oldmessage = Message.find_by_id(@response_to_id)
      if @oldmessage
        @message.to_participant_id = @oldmessage.from_participant_id
        @to_participant = Participant.find_by_id(@message.to_participant_id)
        @to_participant_name = @to_participant.name if @to_participant
        @message.subject = "Re: " + @oldmessage.subject if @oldmessage.subject[0,3] != 'Re:'
      end  
    end
    if not @to_participant and @to_participant_id.to_i > 0
      @to_participant = Participant.find_by_id(@to_participant_id)
      @to_participant_name = @to_participant.name if @to_participant
      @message.to_participant_id = @to_participant_id    
    end
    
    @participant = Participant.includes(:idols).find(current_participant.id)      
    @groupsin = GroupParticipant.where("participant_id=#{current_participant.id}").includes(:group)   
    @groupsadminin = GroupParticipant.where("participant_id=#{current_participant.id} and moderator=1").includes(:group)          
    render :partial=>'edit', :layout=>false
  end  

  def edit
    #-- screen for a editing a message
    @psection = 'mail'
    @from = params[:from] || ''
    @message_id = params[:id]
    @message = Message.find(@message_id)
    render :partial=>'edit', :layout=>false
  end  
  
  def create
    @psection = 'mail'
    @from = params[:from] || ''
    @response_to_id = params[:response_to_id].to_i
    @content = params[:message][:message]
    if params[:message][:to_group_id].to_i > 0
      #-- A message to all members of a group who allow it
      tosend = messsent = emailsent = 0
      @group = Group.includes(:group_participants=>:participant).find(params[:message][:to_group_id])
      tosend = @group.group_participants.length
      logger.info("messages#create sending to #{tosend} group members of group ##{params[:message][:to_group_id]}") 
      for group_participant in @group.group_participants
        @message = Message.new
        @message.from_participant_id = current_participant.id
        @message.to_participant_id = group_participant.participant.id if group_participant.participant
        @message.to_group_id = params[:message][:to_group_id]
        @message.subject = params[:message][:subject]
        @recipient = Participant.find_by_id(@message.to_participant_id)
        @message.message = process_content(@content, @recipient)
        if @message.save     
          messsent += 1
          if group_participant.participant and group_participant.participant.private_email == 'instant'
            #-- Send as an e-mail. emailit is found in the application controller
            @message.sendmethod = 'email'
            @message.emailit
            emailsent += 1
          else
            #-- If we're not sending it instantly, they'll probably get it in a daily or weekly digest  
          end  
        else
          logger.info("messages#create Couldn't save message")  
        end
      end
      render plain: "#{messsent} of #{tosend} messages sent. #{emailsent} sent by e-mail"
    else
      @message = Message.new(message_params)
      @recipient = Participant.find_by_id(@message.to_participant_id)
      @content = @message.message
      @message.from_participant_id = current_participant.id
      @message.sendmethod = 'web'
      @message.message = process_content(@content, @recipient)
      @message.sent_at = Time.now
      if @message.save
        @recipient = Participant.find_by_id(@message.to_participant_id) 
        if @recipient and @recipient.private_email == 'instant'
          #-- Send as an e-mail. 
          @message.sendmethod = 'email'
          @message.emailit
        end  
        follow = Follow.where("followed_id=#{@recipient.id} and following_id=#{current_participant.id}").first
        if not follow
          follow = Follow.create(:followed_id => @recipient.id, :following_id => current_participant.id)
        end
        current_participant.update_attribute(:has_participated,true) if not current_participant.has_participated
        render plain: 'Message was successfully sent.'
      else
        logger.info("messages#create Couldn't save message")  
        render plain: 'There was a problem creating the message.'         
      end
    end  

  end  
  
  def show
    @psection = 'mail'
    @inout = params[:inout]
    @message_id = params[:id]
    @message = Message.includes(:sender,:recipient,:group).find(@message_id)
    if @message.to_participant_id == current_participant.id
      @message.read_web = true
      @message.read_at = Time.now
      @message.save
    end
    render :partial=>'show', :layout=>false
  end  
  
#  def check_group_and_dialog  
#    if participant_signed_in? and session[:group_id].to_i == 0 and session[:dialog_id].to_i == 0
#      session[:group_id] = current_participant.last_group_id
#      session[:dialog_id] = current_participant.last_dialog_id
#    end  
#  end

  private

  def process_content(content, recipient)
    # add auth_token to some links like:
    # https://voh.intermix.org/dialogs/7/slider?conv=international
    content.gsub!(%r{//.*?#{ROOTDOMAIN}/[^"')<,:;\s]+}) { |s|
      if s =~ /auth_token=/
        s
      else  
        s += (s =~ /\?/) ? "&" : "?"
        s += "auth_token=#{recipient.authentication_token}"
      end  
    }
    return(content)
  end

  def message_params
    params.require(:message).permit(
    :to_participant_id, :to_group_id, :template_id, :subject, :message, :sendmethod, :response_to_id, :mail_template, :group_id, :dialog_id
    )
  end
  
end
