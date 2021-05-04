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
    update_last_url
  end
  
  def followings
    #-- List the people the user is following
    @participant_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.includes(:idols).find(@participant_id)
    update_last_url
  end 
  
  def friends
    #-- List people that a certain user follows or are followed by
    @section = 'people'
    @psection = 'friends'
    @psection = 'mail'
    @participant_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.includes(:followers,:idols).find(@participant_id)
    
    @friends = Follow.where(following_id: current_participant.id, mutual: true)
    @followers = Follow.where(followed_id: current_participant.id, mutual: false)
    @followeds = Follow.where(following_id: current_participant.id, mutual: false)
    
    # Could not find the source association(s) :follower or :followers in model Follow.  Try 'has_many :followers, :through => :followeds, :source => <name>'.  Is it one of :followed or :following?
    update_last_url
  end  
  
  def profile
    #-- show somebody's profile
    @participant_id = ( params[:id] || current_participant.id ).to_i    
    #@participant = Participant.find(@participant_id)
    @participant = Participant.includes(:followers,:idols).find(@participant_id)
    logger.info("people#profile showing profile for #{@participant_id}") 
    if @participant
      follow = Follow.where("followed_id=#{@participant_id} and following_id=#{current_participant.id}").first
      @is_following = (follow ? true : false)   
    end 
    update_last_url
  end    
  
  def wall
    #-- Show somebody's wall
    @section = 'wall'
    @psection = 'wall'
    @from = 'wall'
    @participant_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.find(@participant_id)
    @sortby = params[:sortby] || "items.id desc"
    @perscr = params[:perscr].to_i || 25
    
    crit = {}
    crit[:posted_by] = @participant_id
    rootonly = false
    
    items,ratings,@title = Item.get_items(crit,current_participant,rootonly)
    @itemsproc,@extras = Item.get_itemsproc(items,ratings,current_participant.id,rootonly)
    @items = Item.get_sorted(items,@itemsproc,@sortby,rootonly)
       
    update_last_url
    
    @items = @items.paginate page: @page, per_page: 10  
      
  end
  
  def follow
    #-- Follow or unfollow somebody. current_participant wants to follow/unfollow @participant
    onoff = (params[:onoff].to_i == 1)  # Want to follow
    @participant_id = params[:id]
    @participant = Participant.includes(:followers,:idols).find(@participant_id)
    
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
      end
      current_participant.update_attribute(:has_participated,true) if not current_participant.has_participated
    elsif not onoff and follow
      #-- Want to unfollow, and there's a record
      follow.destroy  
      @is_following = false    
    elsif follow
      @is_following = true
    elsif not follow
      @is_following = false    
    end  
    
    render :partial => "follow", :layout => false
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
