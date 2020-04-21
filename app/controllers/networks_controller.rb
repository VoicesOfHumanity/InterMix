class NetworksController < ApplicationController

	layout "front"
  before_action :set_network, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_participant!
  before_action :check_is_admin, except: [:index]

  def index
    # Show a list of networks
    @section = 'communities'
    @csection = params[:csection].to_s
    @csection = 'mynet' if @csection == ''
    @sort = params[:sort] || 'activity'
    
    networks = []
    if @csection == 'mynet'
      networks2 = Network.all
      for network in networks2
        for com in network.communities
          if current_participant.tag_list_downcase.include?(com.tagname.downcase)
            networks << network
            break
          end
        end
      end
    else
      @csection = 'allnet'
      networks = Network.all
    end
    @networks = networks
    
    # sort
    if @sort == 'activity'
      @networks.sort! { |a,b| b.send(@sort) <=> a.send(@sort) } 
    else
      @networks.sort! { |a,b| a.send(@sort) <=> b.send(@sort) } 
    end
    
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_network
      @network_id = params[:id]
      @network = Network.find(@network_id)
    end

    # Only allow a trusted parameter "white list" through.
    def network_params
      params.require(:network).permit(:name)
    end
    
    def check_is_admin
      @network_id = params[:id].to_i
      @is_admin = false
      @is_super = false
      if current_participant.sysadmin
        @is_admin = true
        @is_super = true
      else
        if not @network
          set_network
        end
        if @network.created_by == current_participant.id
          @is_admin = true
        end
      end
    end

end