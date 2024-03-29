require 'will_paginate/array'

class MessagesController < ApplicationController
  
  layout "front"
  before_action :authenticate_user_from_token!
  before_action :authenticate_participant!, :check_group_and_dialog

  include ActivityPub
  
  def index
    @section = 'profile'
    @psection = 'mail'
    
    @from = params[:from] || ''
    
    @sortby = params[:sortby] || "messages.id desc"
    @perscr = params[:perscr].to_i || 25
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    
    @inout = params[:inout] || 'in'
    @newmess = (params[:newmess].to_i == 1) 
    @to_remote_actor_id = params[:to_remote_actor_id].to_i
    @to_participant_id = params[:to_participant_id].to_i
    @to_friend_id = params[:to_friend_id].to_i
    
    @messages = Message.where(nil)
      
    if @inout == 'conv'
      @participant_id = ( params[:participant_id] || current_participant.id ).to_i
      @participant = Participant.find(@participant_id)
      @messages = @messages.where("(from_participant_id=#{current_participant.id} and to_participant_id=#{@participant_id}) or (from_participant_id=#{@participant_id} and to_participant_id=#{current_participant.id})")        
      @messages = @messages.includes([:sender,:remote_sender,:recipient,:remote_recipient])
    elsif @inout == 'out'  
      @messages = @messages.where(:from_participant_id => current_participant.id) 
      @messages = @messages.includes([:recipient, :remote_recipient])
    else
      @messages = @messages.where(:to_participant_id => current_participant.id)
      @messages = @messages.includes([:sender, :remote_sender])
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
    @to_remote_actor_id = params[:to_remote_actor_id].to_i
    @message = Message.new
    @message.to_participant_id = 0
    @to_name = '???'
    if @response_to_id > 0
      @message.response_to_id = @response_to_id
      @oldmessage = Message.find_by_id(@response_to_id)
      if @oldmessage
        @message.to_participant_id = @oldmessage.from_participant_id
        @message.to_remote_actor_id = @oldmessage.from_remote_actor_id
        if @oldmessage.subject.to_s != '' and @oldmessage.subject[0,3] != 'Re:'
          @message.subject = "Re: " + @oldmessage.subject
        else  
          @message.subject = "Re: " + @oldmessage.plain[0..30]
        end
      end  
    else
      @message.to_participant_id = @to_participant_id
      @message.to_remote_actor_id = @to_remote_actor_id        
    end
    if @message.to_participant_id.to_i > 0
      @to_participant = Participant.find_by_id(@message.to_participant_id)
      if @to_participant
        @to_name = @to_participant.name
        follow = Follow.where(followed_id: current_participant.id, following_id: @to_participant_id).first
        if follow
          logger.info("messages#new #{@to_participant_id} is following me")
          @message.to_friend_id = follow.id
          @follow_mutual = follow.mutual
        else
          logger.info("messages#new #{@to_participant_id} is not following me")
        end
      end
    elsif @message.to_remote_actor_id.to_i > 0
      @to_remote_actor = RemoteActor.find_by_id(@message.to_remote_actor_id)
      if @to_remote_actor
        @to_name = "#{@to_remote_actor.account} : #{@to_remote_actor.name}"
        follow = Follow.where(followed_id: current_participant.id, following_remote_actor_id: @to_remote_actor_id).first
        if follow
          @message.to_friend_id = follow.id
          @follow_mutual = follow.mutual
        end        
      end
    end    

    logger.info("messages#new to_friend_id: #{@message.to_friend_id} follow_mutual:#{@follow_mutual}")

    # We'll be able to send to anybody who's following me, whether it is mutual or not
    #@friends = Follow.where(following_id: current_participant.id, mutual: true).includes(:idol, :remote_idol)
    @followers = Follow.where(followed_id: current_participant.id).includes(:follower, :remote_follower)
        
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

    @message = Message.new(message_params)
    
    if @message.to_participant_id.to_i == 0
      # Assume it is a message to ourselves
      @message.to_participant_id = current_participant.id
    end
    
    if @message.to_friend_id.to_i > 0
      # The follow ID of somebody following us
      followme = Follow.find_by_id(@message.to_friend_id)
      if followme
        followthem = nil
        if followme.following_id.to_i > 0
          @message.to_participant_id = followme.following_id
          followthem = Follow.where(followed_id: @message.to_participant_id, following_id: current_participant.id).first
        elsif followme.following_remote_actor_id.to_i > 0
          @message.to_remote_actor_id = followme.following_remote_actor_id
          followthem = Follow.where(followed_remote_actor_id: @message.to_remote_actor_id, following_id: current_participant.id).first
        end
        logger.info("messages#create Sending to follower #{followthem.id} Participant:#{@message.to_participant_id.to_i} Remote:#{@message.to_remote_actor_id.to_i}") if followthem
        if not followthem
          # Follow them back, if we aren't already
          followthem = Follow.new(following_id: current_participant.id, mutual: true)
          if @message.to_remote_actor_id.to_i > 0
            followthem.followed_remote_actor_id = @message.to_remote_actor_id
          else
            followthem.followed_id = @message.to_participant_id
          end
          followthem.save
          followme.mutual = true
          followme.save
        end
      else
        logger.info("messages#create Didn't find follower #{@message.to_friend_id}")
      end
    end 
    
    
    @content = @message.message
    @message.from_participant_id = current_participant.id
    @message.message = process_content(@content, @recipient)
    
    if @message.to_remote_actor_id.to_i > 0 and @message.to_participant_id.to_i == 0
      @message.int_ext = 'ext'
    end

    if @message.save
      
      if @message.to_participant_id.to_i > 0
        # Internal message
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
        @message.sent_at = Time.now        
        @message.sendmethod = 'web'
        @message.save
        notice = 'Message was successfully sent.'
      elsif @message.to_remote_actor_id.to_i > 0
        # Remote message
        from_participant = Participant.find_by_id(@message.from_participant_id)
        to_remote_actor = RemoteActor.find_by_id(@message.to_remote_actor_id)
        
        res = send_note(from_participant, to_remote_actor, @message)
        
        if res
          @message.sendmethod = 'activitypub'
          @message.sent_at = Time.now
          @message.remote_reference = "https://#{BASEDOMAIN}/m_#{current_participant.id}_#{@message.id}"
          @message.save
          notice = 'Message was successfully sent to the remote user.'
        else
          notice = 'The message was stored, but there was a problem sending it to the remote user.'          
        end
      else
        notice = "The message was stored, but something went wrong. Participant:#{@message.to_participant_id.to_i} Remote:#{@message.to_remote_actor_id.to_i}"
      end
      
      current_participant.update_attribute(:has_participated,true) if not current_participant.has_participated
      render plain: notice
    else
      logger.info("messages#create Couldn't save message")  
      render plain: 'There was a problem creating the message.'         
    end

  end  
  
  def show
    @psection = 'mail'
    @inout = params[:inout]
    @message_id = params[:id]
    @message = Message.includes(:sender, :remote_sender, :recipient).find(@message_id)
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
      elsif recipient  
        s += (s =~ /\?/) ? "&" : "?"
        s += "auth_token=#{recipient.authentication_token}"
      else
        s
      end  
    }
    return(content)
  end

  def message_params
    params.require(:message).permit(
    :to_participant_id, :to_remote_actor_id, :to_friend_id, :template_id, :subject, :message, :sendmethod, :response_to_id, :mail_template, :group_id, :dialog_id
    )
  end
  
end
