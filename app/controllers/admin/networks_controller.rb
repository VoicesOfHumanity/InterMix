class Admin::NetworksController < ApplicationController

	layout "admin"
  append_before_action :authenticate_participant!

  before_action :set_network, only: [:show, :edit, :update, :destroy, :communities, :community_add, :community_del]

  def search
    @heading = 'Networks'
    @sort = ['name','']
  end  

  def index
    @networks = Network.all
    
    network_id = params[:network_id].to_i
    name = params[:name]

    @per_page = (params[:per_page] || 30).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    sort1 = (params[:sort1] || 'tagname').to_s
    sort2 = params[:sort2].to_s    
    xorder = sort1
    xorder += "," if xorder!="" and sort2!=""
    xorder += sort2 if sort2!=""

    xcond = "1=1"
    if name != ''
      xcond = "name like '#{name}%'"
    end

    if network_id>0
      @networks = [Network.find(network_id)]
    else  
      @networks = Network.where(xcond).order(xorder).paginate(:page=>@page, :per_page => @per_page)  
    end
    
    respond_to do |format|
      format.html { render :partial=>'list', :layout=>false }
      format.xml  { render :xml => @networks }
    end
  end

  def show
    respond_to do |format|
      format.html { render :partial=>'show', :layout=>false }
      format.xml  { render :xml => @network }
    end
  end

  def new
    @network = Network.new
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @netork }
    end
  end

  def edit
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @network }
    end
  end

  def create
    @network = Network.new(params[:network])
    @network.created_by = current_participant.id
    respond_to do |format|
      if @network.save
        format.html { render :partial=>'show', :layout=>false, :notice => 'Network was successfully created.' }
        format.xml  { render :xml => @network, :status => :created, :location => @community }
      else
        format.html { render :partial=>'edit', :layout=>false }
        format.xml  { render :xml => @network.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @network.update_attributes(params[:network])
        format.html { render :partial=>'show', :layout=>false, :notice => 'Network was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :partial => "edit", :layout=>false }
        format.xml  { render :xml => @Network.errors, :status => :unprocessable_entity }
      end
    end    
  end

  def destroy
    @network.destroy
    respond_to do |format|
      format.html { render plain: "<p>Network ##{params[:id]} has been deleted</p>" }
      format.xml  { head :ok }
    end
  end



  def communities
    #-- Return a list of the communities in this network
    @communities = @network.communities
    @allcommunities = Community.where("fullname!=''")
    render :partial=>"communities", :layout=>false
  end  
  
  def community_add
    #-- Add a community to the network
    @community_id = params[:community_id]
    community_network = NetworkCommunity.where(network_id: @network_id, community_id: @community_id).first
    if not community_network
      community_network = NetworkCommunity.create(network_id: @network_id, community_id: @community_id, created_by: current_participant.id)
    end
    communities    
  end 
  
  def community_del 
    #-- Remove a community from the network
    community_ids = params[:community_ids]
    for community_id in community_ids
      com = NetworkCommunity.where(network_id: @network.id, community_id: community_id).first
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
      params.require(:network).permit(:name, :created_by, :age, :gender, :geo_level)
    end

end