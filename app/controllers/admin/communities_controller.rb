class Admin::CommunitiesController < ApplicationController
  
	layout "admin"
  append_before_action :authenticate_participant!

  def search
    @heading = 'Communities'
    @sort = ['id desc','']
  end  
  
  # GET /communities
  # GET /communities.xml
  def index
    community_id = params[:community_id].to_i

    @per_page = (params[:per_page] || 30).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    sort1 = (params[:sort1] || 'id desc').to_s
    sort2 = params[:sort2].to_s    
    xorder = sort1
    xorder += "," if xorder!="" and sort2!=""
    xorder += sort2 if sort2!=""

    xcond = "1=1"

    if community_id>0
      @communities = [Community.find(community_id)]
    else  
      @communities = Community.where(xcond).order(xorder).paginate(:page=>@page, :per_page => @per_page)  
    end
    
    respond_to do |format|
      format.html { render :partial=>'list', :layout=>false }
      format.xml  { render :xml => @communities }
    end
  end

  # GET /communities/1
  # GET /communities/1.xml
  def show
    @community = Community.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'show', :layout=>false }
      format.xml  { render :xml => @community }
    end
  end

  # GET /communities/new
  # GET /communities/new.xml
  def new
    @community = Community.new
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @community }
    end
  end

  # GET /communities/1/edit
  def edit
    @community = Community.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @community }
    end
  end

  # POST /communities
  # POST /communities.xml
  def create
    @community = Community.new(params[:community])

    respond_to do |format|
      if @community.save
        format.html { render :partial=>'show', :layout=>false, :notice => 'Community was successfully created.' }
        format.xml  { render :xml => @community, :status => :created, :location => @community }
      else
        format.html { render :partial=>'edit', :layout=>false }
        format.xml  { render :xml => @Community.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /communities/1
  # PUT /communities/1.xml
  def update
    @community = Community.find(params[:id])

    respond_to do |format|
      if @community.update_attributes(params[:community])
        format.html { render :partial=>'show', :layout=>false, :notice => 'Group was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :partial => "edit", :layout=>false }
        format.xml  { render :xml => @Community.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /communities/1
  # DELETE /communities/1.xml
  def destroy
    @community = Community.find(params[:id])
    @community.destroy

    respond_to do |format|
      format.html { render :text=>"<p>Community ##{params[:id]} has been deleted</p>" }
      format.xml  { head :ok }
    end
  end
    
end
