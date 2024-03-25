# encoding: utf-8

class Admin::ComplaintsController < ApplicationController
  
	layout "admin"
  append_before_action :authenticate_participant!

  def search
    @heading = 'Complaints'
    @sort = ['id desc','']
  end  
  
  # GET /complaints
  # GET /complaints.xml
  def index
    complaint_id = params[:complaint_id].to_i

    @per_page = (params[:per_page] || 30).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    sort1 = (params[:sort1] || 'id desc').to_s
    sort2 = params[:sort2].to_s    
    xorder = sort1
    xorder += "," if xorder!="" and sort2!=""
    xorder += sort2 if sort2!=""

    xcond = "1=1"

    if complaint_id>0
      @complaints = [Complaint.find(complaint_id)]
    else  
      @complaints = Complaint.where(xcond).order(xorder).paginate(:page=>@page, :per_page => @per_page)  
    end
    
    respond_to do |format|
      format.html { render :partial=>'list', :layout=>false }
      format.xml  { render :xml => @complaints }
    end
  end

  # GET /complaints/1
  # GET /complaints/1.xml
  def show
    @complaint = Complaint.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'show', :layout=>false }
      format.xml  { render :xml => @complaint }
    end
  end

  # GET /complaints/new
  # GET /complaints/new.xml
  def new
    @complaint = Complaint.new
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @complaint }
    end
  end

  # GET /complaints/1/edit
  def edit
    @complaint = Complaint.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @complaint }
    end
  end

  # POST /complaints
  # POST /complaints.xml
  def create
    @complaint = Complaint.new(params[:complaint])

    respond_to do |format|
      if @complaint.save
        format.html { render :partial=>'show', :layout=>false, :notice => 'Complaint was successfully created.' }
        format.xml  { render :xml => @complaint, :status => :created, :location => @complaint }
      else
        format.html { render :partial=>'edit', :layout=>false }
        format.xml  { render :xml => @complaint.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /complaints/1
  # PUT /complaints/1.xml
  def update
    @complaint = Complaint.find(params[:id])

    respond_to do |format|
      if @complaint.update_attributes(params[:complaint])
        format.html { render :partial=>'show', :layout=>false, :notice => 'Group was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :partial => "edit", :layout=>false }
        format.xml  { render :xml => @complaint.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /complaints/1
  # DELETE /complaints/1.xml
  def destroy
    @complaint = Complaint.find(params[:id])
    @complaint.destroy

    respond_to do |format|
      format.html { render plain: "<p>Complaint ##{params[:id]} has been deleted</p>" }
      format.xml  { head :ok }
    end
  end
  
end
