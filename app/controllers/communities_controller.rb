class CommunitiesController < ApplicationController
 
	layout "front"
  append_before_action :authenticate_user_from_token!
  append_before_action :authenticate_participant!

  def index
    #-- Show an list of communities
    @section = 'communities'
    

    if params[:which].to_s == 'my'
      comtag_list = ''
      comtags = {}
      for tag in current_participant.tag_list
        comtags[tag] = true
      end
      @comtag_list = comtags.collect{|k, v| "'#{k}'"}.join(',')
      @communities = Community.where("tagname in (#{@comtag_list})").order('id')
      @csection = 'my'      
    else
      @communities = Community.order('id')
      @csection = 'all'
    end
    
  end  




end