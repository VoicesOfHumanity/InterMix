class Admin::ConversationsController < ApplicationController

	layout "admin"
  append_before_action :authenticate_participant!

  before_action :set_network, only: [:show, :edit, :update, :destroy, :communities, :community_add, :community_del]

  def search
    @heading = 'Networks'
    @sort = ['name','']
  end  


  def communities
    #-- Return a list of the communities in this conversation
    @communities = @network.communities
    @allcommunities = Community.where("fullname!=''")
    render :partial=>"communities", :layout=>false
  end  
  
  def community_add
    #-- Add a community to the network
    @community_id = params[:community_id]
    community_network = CommunityNetwork.where(network_id: @network_id, community_id: @community_id).first
    if not community_network
      community_network = CommunityNetwork.create(network_id: @network_id, community_id: @community_id)
    end
    communities    
  end 
  
  def community_del 
    #-- Remove a community from the conversation
    community_ids = params[:community_ids]
    for community_id in community_ids
      com = CommunityNetwork.where(network_id: @network.id, community_id: community_id).first
      if com
        com.destroy
      end
    end
    communities
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_network
      @network = Network.find(params[:id])
      @network_id = @network.id
    end

    # Only allow a trusted parameter "white list" through.
    def network_params
      params.require(:network).permit(:name, :created_by)
    end

end