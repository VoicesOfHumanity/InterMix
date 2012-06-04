class PeopleController < ApplicationController

  layout "front"
  before_filter :authenticate_participant!

  def index
    #-- Show people who're visible to whoever's logged in
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
    
    @participants = Participant.scoped
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
    @participant_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.includes(:followers,:idols).find(@participant_id)
    
    # Could not find the source association(s) :follower or :followers in model Follow.  Try 'has_many :followers, :through => :followeds, :source => <name>'.  Is it one of :followed or :following?
    update_last_url
  end  
  
  def profile
    #-- show somebody's profile
    @participant_id = ( params[:id] || current_participant.id ).to_i
    #@participant = Participant.find(@participant_id)
    @participant = Participant.includes(:followers,:idols).find_by_id(@participant_id)
    if @participant
      follow = Follow.where("followed_id=#{@participant_id} and following_id=#{current_participant.id}").find(:first)
      @is_following = (follow ? true : false)   
    end 
    update_last_url
  end    
  
  def follow
    #-- Follow or unfollow somebody
    onoff = (params[:onoff].to_i == 1)
    @participant_id = params[:id]
    follow = Follow.where("followed_id=#{@participant_id} and following_id=#{current_participant.id}").find(:first)
    if onoff and not follow
      follow = Follow.create(:followed_id => @participant_id, :following_id => current_participant.id)

      @participant = Participant.includes(:followers,:idols).find(@participant_id)
      follow = Follow.where("followed_id=#{@participant_id} and following_id=#{current_participant.id}").find(:first)
      @is_following = (follow ? true : false)    
      
      if @participant and @participant.system_email == 'instant'
        #-- Send as an e-mail. emailit is found in the application controller 
        @message = Message.new
        @message.subject = "#{current_participant.name} is now following you"
        @message.message = "<p><a href=\"http://#{BASEDOMAIN}/participant/#{@participant.id}/profile\">#{current_participant.name}</a> is now following you</p>"
        if @is_following
          @message.message += "<p>You are already following them.</p>"
        else  
          @message.message += "<p>You can <a href=\"http://#{BASEDOMAIN}/people/follow?id=#{@participant.id}&onoff=on\">follow them back</a>, if you want.</p>"
        end
        @message.to_participant_id = @participant.id
        @message.from_participant_id = 0
        @message.sendmethod = 'web'
        @message.sent_at = Time.now
        if @message.save        
          @message.sendmethod = 'email'
          @message.emailit
        end
      end
      current_participant.update_attribute(:has_participated,true) if not current_participant.has_participated
      
    elsif not onoff and follow
      follow.destroy  
      @participant = Participant.includes(:followers,:idols).find(@participant_id)
      follow = Follow.where("followed_id=#{@participant_id} and following_id=#{current_participant.id}").find(:first)
      @is_following = (follow ? true : false)    
    end  
    
    render :partial => "follow", :layout => false
  end  

end
