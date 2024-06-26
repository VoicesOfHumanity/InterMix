require 'will_paginate/array'

class PeopleController < ApplicationController

  layout "front"
  before_action :authenticate_user_from_token!
  before_action :authenticate_participant!, :check_group_and_dialog

  def index
    #-- Show people who're visible to whoever's logged in
    @section = 'people'
    @psection = 'friends'
    getlist  
    update_last_url
  end  

  def list
    getlist
    render :partial=>'list', :layout=>false  
  end  
  
  def getlist
    @section = 'people'
    @from = 'people'
    
    @sortby = params[:sortby] || "participants.id desc"
    @perscr = (params[:perscr] || 25).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    @perscr = 25 if @perscr < 1
    
    @participants = Participant.where(nil)
    @participants = @participants.includes([:groups])
    @participants = @participants.order(@sortby)
    @participants = @participants.paginate :page=>@page, :per_page => @perscr    
  end  
  
  def followeds
    #-- List people who follow a certain user
    @participant_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.includes(:followers).find(@participant_id)
    if @participant.status == 'removed'
      redirect_to '/people/removed' and return
    end

    update_last_url
  end
  
  def followings
    #-- List the people the user is following
    @participant_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.includes(:idols).find(@participant_id)
    if @participant.status == 'removed'
      redirect_to '/people/removed' and return
    end

    update_last_url
  end 
  
  def friends
    #-- List people that a certain user follows or are followed by
    @section = 'people'
    @psection = 'friends'
    @psection = 'mail'
    @participant_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.includes(:followers,:idols).find(@participant_id)
    if @participant.status == 'removed'
      redirect_to '/people/removed' and return
    end
    
    @friends = Follow.where(following_id: current_participant.id, mutual: true)
    @followers = Follow.where(followed_id: current_participant.id, mutual: false)
    @followeds = Follow.where(following_id: current_participant.id, mutual: false)
    
    # Could not find the source association(s) :follower or :followers in model Follow.  Try 'has_many :followers, :through => :followeds, :source => <name>'.  Is it one of :followed or :following?
    update_last_url
  end  
  
  def profile
    #-- show somebody's profile
    section = 'people'
    @participant_id = ( params[:id] || current_participant.id ).to_i    
    #@participant = Participant.find(@participant_id)
    @participant = Participant.includes(:followers,:idols).find(@participant_id)
    if @participant.status == 'removed'
      redirect_to '/people/removed' and return
    end
    logger.info("people#profile showing profile for #{@participant_id}") 
    if @participant
      follow = Follow.where("followed_id=#{@participant_id} and following_id=#{current_participant.id}").first
      @is_following = (follow ? true : false)   
    end 
    update_last_url
  end
  
  def remote_profile
    # A remote_actor from Activitypub
    section = 'people'
    @remote_actor_id = params[:remote_actor_id]
    
    @remote_actor = RemoteActor.find_by_id(@remote_actor_id)
    
    if @remote_actor
      follow = Follow.where("followed_remote_actor_id=#{@remote_actor_id} and following_id=#{current_participant.id}").first
      @is_following = (follow ? true : false)   
      @mutual = (@is_following and follow.mutual)
    end    
    
  end 
  
  def wall
    #-- Show somebody's wall
    @section = 'wall'
    @psection = 'wall'
    @from = 'wall'
    @in = 'wall'
    @participant_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.find(@participant_id)
    @sortby = params[:sortby] || "items.id desc"
    @perscr = params[:perscr].to_i || 25
    @page = params[:page].to_i
    @page = 1 if @page <= 0
    
    @otherwall = true

    if @participant.status == 'removed'
      redirect_to '/people/removed' and return
    end  
        
    #crit = {}
    #crit[:posted_by] = @participant_id
    #rootonly = false
    
    #items,ratings,@title = Item.get_items(crit,current_participant,rootonly)
    #@itemsproc,@extras = Item.get_itemsproc(items,ratings,current_participant.id,rootonly)
    #@items = Item.get_sorted(items,@itemsproc,@sortby,rootonly)
       
    update_last_url
    
    #@items = @items.paginate page: @page, per_page: 10  

    # defaults
    @geo_level = 6
    @nvaction = false
    @include_nvaction = false
    @messtag = ''
    @datetype = 'fixed'
    @datefixed = 'month'
    @sortby = (@in == 'main' ? 'items.id desc' : '*value*')
    @threads = 'flat'
    @perspective = ''
    
    @geo_levels = [
      [6,'Planet&nbsp;Earth'],
      [5,'My&nbsp;Nation'],
      [4,'State/Province'],
      [3,'My&nbsp;Metro&nbsp;region'],
      [2,'My&nbsp;County'],
      [1,'My&nbsp;City/Town']
    ]
         
    @posted_by = @participant_id
    @posted_by_participant = @participant
     
  end
  
  def follow
    #-- Follow or unfollow somebody. current_participant wants to follow/unfollow @participant
    # NB: WHAT ABOUT REMOTE? following happens in activitypub/follow_account
    onoff = (params[:onoff].to_i == 1)  # Want to follow
    @participant_id = params[:id]
    @participant = Participant.includes(:followers,:idols).find(@participant_id)
    
    @showmess = ""
    
    follow = Follow.where("followed_id=#{@participant_id} and following_id=#{current_participant.id}").first
    if onoff and not follow
      #-- Want to follow, and there isn't already a record of having done that
      follow = Follow.create(:followed_id => @participant_id, :following_id => current_participant.id)
      
      they_follow = Follow.where("followed_id=#{current_participant.id} and following_id=#{@participant_id}").first
      @they_following = (they_follow ? true : false)    
      
      if @participant
        #-- Send as an e-mail. emailit is found in the application controller 
        @message = Message.new
        @message.subject = "#{current_participant.name} is now following you"
        @message.message = "<p><a href=\"https://#{BASEDOMAIN}/participant/#{current_participant.id}/profile?auth_token=#{@participant.authentication_token}\">#{current_participant.name}</a> is now following you</p>"
        if @they_following
          @message.message += "<p>You are already following #{current_participant.them}.</p>"
        else  
          @message.message += "<p>You can <a href=\"https://#{BASEDOMAIN}/participant/#{current_participant.id}/profile?auth_token=#{@participant.authentication_token}\">follow #{current_participant.them} back</a>, if you want.</p>"
        end
        @message.to_participant_id = @participant.id
        @message.from_participant_id = 0
        @message.sendmethod = 'web'
        @message.sent_at = Time.now
        if @message.save      
          if @participant.system_email == 'instant'  
            @message.sendmethod = 'email'
            @message.emailit
          else
            @message.email_sent = false
          end  
          @message.save
        end
        @is_following = true
        @showmess = "You are now following #{@participant.name}."
      end
      current_participant.update_attribute(:has_participated,true) if not current_participant.has_participated
    elsif not onoff and follow
      #-- Want to unfollow, and there's a record
      follow.destroy  
      @is_following = false  
      @showmess = "You are now no longer following #{@participant.name}."  
    elsif follow
      @is_following = true
      @showmess = "You are already following #{@participant.name}."
    elsif not follow
      @is_following = false    
      @showmess = "You are not following #{@participant.name}."
    end  
    
    #-- Check what is mutual
    following = Follow.where("following_id=#{current_participant.id} and followed_id=#{@participant.id}").first
    followed = Follow.where("following_id=#{@participant.id} and followed_id=#{current_participant.id}").first
    if following and followed
      logger.info("people#follow it is now mutual for #{current_participant.id} and #{@participant.id}")
      following.mutual = true
      following.save
      followed.mutual = true
      followed.save
    elsif following
      logger.info("people#follow #{current_participant.id} follows #{@participant.id}, but not the reverse. Turning mutual off")      
      following.mutual = false
      following.save
    elsif followed
      logger.info("people#follow #{@participant.id} follows #{current_participant.id}, but not the reverse. Turning mutual off")      
      followed.mutual = false
      followed.save  
    end
    
    render :partial => "follow", :layout => false
  end  

  def removed
    # If a participant has been removed, we'll show people this screen
    @section = 'people'
    @psection = 'removed'
  end

  protected
  
  def check_group_and_dialog  
    if participant_signed_in? and session[:group_id].to_i == 0 and session[:dialog_id].to_i == 0
      session[:group_id] = current_participant.last_group_id
      session[:dialog_id] = current_participant.last_dialog_id
      if session[:group_id].to_i > 0
        @group_id = session[:group_id]
        @group = Group.find_by_id(@group_id)
        if @group
          session[:group_name] = @group.name
          session[:group_prefix] = @group.shortname
          @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).first
          @is_member = @group_participant ? true : false
          session[:group_is_member] = @is_member
        end
      end
      if session[:dialog_id].to_i > 0
        @dialog_id = session[:dialog_id]
        @dialog = Dialog.find_by_id(@dialog_id)
        if @dialog
          session[:dialog_name] = @dialog.name
          session[:dialog_prefix] = @dialog.shortname
        end
      end
    end  
  end

end
