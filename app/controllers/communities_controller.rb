class CommunitiesController < ApplicationController
 
	layout "front"
  append_before_action :authenticate_user_from_token!
  append_before_action :authenticate_participant!
  append_before_action :check_is_admin, except: :index

  def index
    #-- Show an list of communities
    @section = 'communities'
    
    if not params.has_key?(:which)
      session[:curcomtag] = ''
      session[:curcomid] = 0
    end
    
    if params.has_key?(:sort)
      sort = params[:sort]
      if sort == 'tag'
        @sort = 'tagname'
      elsif sort == 'activity'
        @sort = 'activity'  
      elsif sort == 'id'
        @sort = 'id desc'  
      else
        @sort = 'id desc'
      end     
    else
      @sort = 'activity'
    end

    if params[:which].to_s == 'all' or current_participant.tag_list.length == 0
      communities = Community.all
      @csection = 'all'      
    else
      comtag_list = ''
      comtags = {}
      for tag in current_participant.tag_list
        comtags[tag] = true
      end
      @comtag_list = comtags.collect{|k, v| "'#{k}'"}.join(',')
      communities = Community.where("tagname in (#{@comtag_list})")
      @csection = 'my'      
    end

    if ['id','tag'].include?(sort) or @sort == 'id desc'
      communities = communities.order(@sort)      
    end
    
    @communities = []
    communities.each do |community|
      #community.members = community.member_count
      community.activity = community.activity_count
      @communities << community
    end
    
    if ['id','tag'].include?(sort) or @sort == 'id desc'
    else
      @communities.sort! { |a,b| b.send(@sort) <=> a.send(@sort) }
    end
       
    @sort = sort 
    
  end  

  def show
    #-- The info page
    @community_id = params[:id].to_i
    @community = Community.find(@community_id)
    @comtag = @community.tagname   
    session[:curcomtag] = @comtag 
    session[:curcomid] = @community_id 
    @section = 'communities'
    @csection = 'info'
    
    @data = {}
    @data['new_posts'] = @community.activity_count
    @data['num_members'] = @community.member_count
    geo = @community.geo_counts
    logger.info("communities#show geo: #{geo.inspect}")
    @data['nation_count'] = geo[:nations]
    @data['state_count'] = geo[:states]
    @data['metro_count'] = geo[:metros]
    @data['city_count'] = geo[:cities]
  end
  
  def members
    @community_id = params[:id].to_i
    @community = Community.find(@community_id)
    @comtag = @community.tagname
    session[:curcomtag] = @comtag 
    session[:curcomid] = @community_id 
    @section = 'communities'
    @csection = 'members'
    
    members = Participant.tagged_with(@comtag)
    
    # Get activity in the past month, and sort by it
    @members = []
    for member in members
      member.activity = Item.where("intra_com='@#{@comtag}'").where(posted_by: member.id).where('created_at > ?', 31.days.ago).count
      @members << member
    end

    @sort = 'activity'
    @members.sort! { |a,b| b.send(@sort) <=> a.send(@sort) }
        
  end

  def edit
    #-- Edit page
    @community_id = params[:id].to_i
    @community = Community.find(@community_id)
    @comtag = @community.tagname   
    session[:curcomtag] = @comtag 
    session[:curcomid] = @community_id 
    @section = 'communities'
    @csection = 'edit'
    
    @participants = Participant.where(nil)
    
  end
  
  def update
    @community_id = params[:id].to_i
    @community = Community.find(@community_id)
    @community.update_attributes(community_params)
    @community.save
    redirect_to :action=>:show, :notice => 'Community was successfully updated.'
  end

  def admins
    #-- Return a list of the admins for this community, as part of the edit page
    @community_id = params[:id].to_i
    @community = Community.includes(:moderators).find(@community_id)
    render :partial=>"adminsedit", :layout=>false
  end  
  
  def admin_add
    #-- Add a community admin
    @community_id = params[:id].to_i
    @community = Community.find_by_id(@community_id)
    @participant_id = params[:participant_id]
    participant = Participant.find_by_id(@participant_id)
    community_admin = CommunityAdmin.where(["community_id = ? and participant_id = ?", @community_id, @participant_id]).first
    if @is_admin and not community_admin
      community_admin = CommunityAdmin.create(:community_id => @community_id, :participant_id => @participant_id)
      if participant
        participant.tag_list.add(@community.tagname)
        participant.save
      end
    end
    admins    
  end 
  
  def admin_del 
    #-- Delete a community admin
    @community_id = params[:id].to_i
    participant_ids = params[:participant_ids]
    for participant_id in participant_ids
      participant = Participant.find_by_id(participant_id)
      community_admin = CommunityAdmin.where(["community_id = ? and participant_id = ?", @community_id, participant_id]).first
      if @is_admin and community_admin
        community_admin.destroy
      end
    end
    admins
  end

  protected

  def community_params
    params.require(:community).permit(:description, :logo, :twitter_post, :twitter_username, :twitter_oauth_token, :twitter_oauth_secret, :twitter_hash_tag, :tweet_approval_min, :tweet_what)
  end
  
  def check_is_admin
    @community_id = params[:id].to_i
    @is_admin = false
    if current_participant.sysadmin
      @is_admin = true
    else
      admin = CommunityAdmin.where(["community_id = ? and participant_id = ?", @community_id, current_participant.id]).first
      if admin
        @is_admin = true
      end
    end
  end

end