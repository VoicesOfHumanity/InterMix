class CommunitiesController < ApplicationController
 
	layout "front"
  append_before_action :authenticate_user_from_token!
  append_before_action :authenticate_participant!

  def index
    #-- Show an list of communities
    @section = 'communities'
    
    
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
        
    
  end  




end