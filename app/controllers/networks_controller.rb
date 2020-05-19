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
    
    @gender_options = []
    gender_texts = {208=>"Women", 207=>"Men", 408=>"Simply-Human"}
    gender = 0
    @age_options = []
    age_texts = {405=>"Youth", 406=>"Experience", 407=>"Wisdom", 409=>"Simply-Human"}
    age = 0    
    current_participant.metamap_nodes.each do |mn|
      if mn.metamap_id == 3
        gender = mn.id
      elsif mn.metamap_id == 5
        age = mn.id
      end
    end  
    if age > 0
      @age_options = [[age_texts[age], age]]
    end
    if gender > 0
      @gender_options = [[gender_texts[gender], gender]]
    end
    
  end

  def edit
  end

  def create
    @network = Network.new(network_params)
    @network.created_by = current_participant.id

    if @network.save
      
      comarray = []
      if params[:communities]
        for com in params[:communities]
          com = com.to_i
          netcom = NetworkCommunity.where(network_id: @network.id, community_id: com.to_i).first
          if not netcom
            netcom = NetworkCommunity.create(network_id: @network.id, community_id: com.to_i, created_by: current_participant.id)
          end
          comarray << com
        end
        @network.communityarray = comarray
        @network.save
      end
      
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