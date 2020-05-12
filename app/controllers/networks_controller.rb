class NetworksController < ApplicationController

	layout "front"
  before_action :set_network, only: [:show, :edit, :update, :destroy, :members]
  before_action :authenticate_participant!
  before_action :check_is_admin, except: [:index]

  def index
    # Show a list of networks
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
    #@networks = networks

    @networks = []
    networks.uniq.each do |network|
      network.activity = network.activity_count
      @networks << network
    end
    
    # sort
    if @sort == 'activity'
      @networks.sort! { |a,b| b.send(@sort) <=> a.send(@sort) } 
    else
      @networks.sort! { |a,b| a.send(@sort) <=> b.send(@sort) } 
    end
    
  end

  def show
    
    @communities = @network.communities
    
    # sort communities
    @communities = @communities.to_a
    @communities.sort! do |a, b|
      a.tagname <=> b.tagname
    end
    
  end

  def new
    @network = Network.new
    
    comtag_list = ''.dup
    comtags = {}
    for tag in current_participant.tag_list_downcase
      comtags[tag] = true
    end
    comtag_list = comtags.collect{|k, v| "'#{k}'"}.join(',')
    @mycommunities = Community.where("tagname in (#{comtag_list})")
    
  end

  def edit
  end

  def create
    @network = Conversation.new(network_params)

    if @network.save
      redirect_to @network, notice: 'Network was successfully created.'
    else
      render :new
    end
  end

  def update
    if @network.update(network_params)
      redirect_to @network, notice: 'Network was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @network.destroy
    redirect_to networks_url, notice: 'Network was successfully destroyed.'
  end
  
  def members
    # List all members in all the member communities
    puts @network.members
    @members = @network.members
  end  


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_network
      @network_id = params[:id]
      @network = Network.find(@network_id)
      @section = 'communities'
      @csection = params[:csection].to_s
      @csection = 'mynet' if @csection == ''
    end

    # Only allow a trusted parameter "white list" through.
    def network_params
      params.require(:network).permit(:name, :age, :gender, :geo_level)
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