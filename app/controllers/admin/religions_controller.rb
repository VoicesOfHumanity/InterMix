# encoding: utf-8

class Admin::ReligionsController < ApplicationController
  
	layout "admin"
  append_before_action :authenticate_participant!

  def search
    @heading = 'Religions'
    @sort = ['id desc','']
  end  
  
  # GET /religions
  # GET /religions.xml
  def index
    religion_id = params[:religion_id].to_i

    @per_page = (params[:per_page] || 30).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    sort1 = (params[:sort1] || 'id desc').to_s
    sort2 = params[:sort2].to_s    
    xorder = sort1
    xorder += "," if xorder!="" and sort2!=""
    xorder += sort2 if sort2!=""

    xcond = "1=1"

    if religion_id>0
      @religions = [Religion.find(religion_id)]
    else  
      @religions = Religion.where(xcond).order(xorder).paginate(:page=>@page, :per_page => @per_page)  
    end
    
    respond_to do |format|
      format.html { render :partial=>'list', :layout=>false }
      format.xml  { render :xml => @religions }
    end
  end

  # GET /religions/1
  # GET /religions/1.xml
  def show
    @religion = Religion.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'show', :layout=>false }
      format.xml  { render :xml => @religion }
    end
  end

  # GET /religions/new
  # GET /religions/new.xml
  def new
    @religion = Religion.new
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @religion }
    end
  end

  # GET /religions/1/edit
  def edit
    @religion = Religion.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @religion }
    end
  end

  # POST /religions
  # POST /religions.xml
  def create
    @religion = Religion.new(params[:religion])

    respond_to do |format|
      if @religion.save
        format.html { render :partial=>'show', :layout=>false, :notice => 'Religion was successfully created.' }
        format.xml  { render :xml => @religion, :status => :created, :location => @religion }
      else
        format.html { render :partial=>'edit', :layout=>false }
        format.xml  { render :xml => @religion.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /religions/1
  # PUT /religions/1.xml
  def update
    @religion = Religion.find(params[:id])

    respond_to do |format|
      if @religion.update_attributes(params[:religion])
        format.html { render :partial=>'show', :layout=>false, :notice => 'Group was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :partial => "edit", :layout=>false }
        format.xml  { render :xml => @religion.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /religions/1
  # DELETE /religions/1.xml
  def destroy
    @religion = Religion.find(params[:id])
    @religion.destroy

    respond_to do |format|
      format.html { render plain: "<p>Religion ##{params[:id]} has been deleted</p>" }
      format.xml  { head :ok }
    end
  end
 
end
