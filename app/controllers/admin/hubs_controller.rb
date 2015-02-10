# encoding: utf-8

class Admin::HubsController < ApplicationController
  
	layout "admin"
  append_before_action :authenticate_participant!

  def search
    @heading = 'Hubs'
    @sort = ['id desc','']
  end  
  
  # GET /hubs
  # GET /hubs.xml
  def index
    hub_id = params[:hub_id].to_i

    @per_page = (params[:per_page] || 30).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    sort1 = (params[:sort1] || 'id desc').to_s
    sort2 = params[:sort2].to_s    
    xorder = sort1
    xorder += "," if xorder!="" and sort2!=""
    xorder += sort2 if sort2!=""

    xcond = "1=1"

    if hub_id>0
      @hubs = [Hub.find(hub_id)]
    else  
      @hubs = Hub.where(xcond).order(xorder).paginate(:page=>@page, :per_page => @per_page)  
    end
    
    respond_to do |format|
      format.html { render :partial=>'list', :layout=>false }
      format.xml  { render :xml => @hubs }
    end
  end

  # GET /hubs/1
  # GET /hubs/1.xml
  def show
    @hub = Hub.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'show', :layout=>false }
      format.xml  { render :xml => @hub }
    end
  end

  # GET /hubs/new
  # GET /hubs/new.xml
  def new
    @hub = Hub.new
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @hub }
    end
  end

  # GET /hubs/1/edit
  def edit
    @hub = Hub.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @hub }
    end
  end

  # POST /hubs
  # POST /hubs.xml
  def create
    @hub = Hub.new(params[:hub])

    respond_to do |format|
      if @hub.save
        format.html { render :partial=>'show', :layout=>false, :notice => 'Hub was successfully created.' }
        format.xml  { render :xml => @hub, :status => :created, :location => @hub }
      else
        format.html { render :partial=>'edit', :layout=>false }
        format.xml  { render :xml => @hub.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /hubs/1
  # PUT /hubs/1.xml
  def update
    @hub = Hub.find(params[:id])

    respond_to do |format|
      if @hub.update_attributes(params[:hub])
        format.html { render :partial=>'show', :layout=>false, :notice => 'Group was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :partial => "edit", :layout=>false }
        format.xml  { render :xml => @hub.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /hubs/1
  # DELETE /hubs/1.xml
  def destroy
    @hub = Hub.find(params[:id])
    @hub.destroy

    respond_to do |format|
      format.html { render :text=>"<p>Hub ##{params[:id]} has been deleted</p>" }
      format.xml  { head :ok }
    end
  end
  
  def admins
    #-- Return a list of the admins for this hub
    @hub_id = params[:id].to_i

    @hub = Hub.includes(:participants).find(@hub_id)
    
    @participants = Participant.where(nil)
    
    render :partial=>"admins", :layout=>false
  end  
  
  def admin_add
    #-- Add a hub admin
    @hub_id = params[:id].to_i
    @participant_id = params[:participant_id]
    hub_admin = HubAdmin.where(["hub_id = ? and participant_id = ?", @hub_id, @participant_id]).first
    if not hub_admin
      hub_admin = HubAdmin.create(:hub_id => @hub_id, :participant_id => @participant_id)
    end
    admins    
  end 
  
  def admin_del 
    #-- Delete a hub admin
    @hub_id = params[:id].to_i
    participant_ids = params[:participant_ids]
    for participant_id in participant_ids
      hub_admin = HubAdmin.where(["hub_id = ? and participant_id = ?", @hub_id, participant_id]).first
      if hub_admin
        hub_admin.destroy
      end
    end
    admins
  end
  
end
