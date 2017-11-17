class CommunitiesController < ApplicationController
 
	layout "front"
  append_before_action :authenticate_user_from_token!
  append_before_action :authenticate_participant!

  def index
    #-- Show an list of communities
    @section = 'communities'
    @gsection = 'index'
    
    @communities = Community.order('id')
    
  end  




end