# encoding: utf-8

class Admin::TemplatesController < ApplicationController
  
	layout "admin"
  before_filter :authenticate_participant!

  def search
    @heading = 'Templates'
    @sort = ['id desc','']
  end  
  
  # GET /templates
  # GET /templates.xml
  def index
    template_id = params[:template_id].to_i

    @per_page = (params[:per_page] || 30).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    sort1 = (params[:sort1] || 'id desc').to_s
    sort2 = params[:sort2].to_s    
    xorder = sort1
    xorder += "," if xorder!="" and sort2!=""
    xorder += sort2 if sort2!=""

    xcond = "1=1"

    if template_id>0
      @templates = [Template.find(group_id)]
    else  
      @templates = Template.where(xcond).order(xorder).paginate(:page=>@page, :per_page => @per_page)    
    end
    
    respond_to do |format|
      format.html { render :partial=>'list', :layout=>false }
      format.xml  { render :xml => @templates }
    end
  end

  # GET /templates/1
  # GET /templates/1.xml
  def show
    @template = Template.find(params[:id],:include=>[:group])
    respond_to do |format|
      format.html { render :partial=>'show', :layout=>false }
      format.xml  { render :xml => @template }
    end
  end

  # GET /templates/new
  # GET /templates/new.xml
  def new
    @template = Template.new(:mail_web=>'web')
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @template }
    end
  end

  # GET /templates/1/edit
  def edit
    @template = Template.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @template }
    end
  end

  # POST /hubs
  # POST /hubs.xml
  def create
    @template = Template.new(params[:template])

    respond_to do |format|
      if @template.save
        format.html { render :partial=>'show', :layout=>false, :notice => 'Template was successfully created.' }
        format.xml  { render :xml => @template, :status => :created, :location => @template }
      else
        format.html { render :partial=>'edit', :layout=>false }
        format.xml  { render :xml => @template.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /templates/1
  # PUT /templates/1.xml
  def update
    @template = Template.find(params[:id])
    logger.info("Updating template #{@template.id}")

    respond_to do |format|
      if @template.update_attributes(params[:template])
        format.html { render :partial=>'show', :layout=>false, :notice => 'Template was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :partial => "edit", :layout=>false }
        format.xml  { render :xml => @template.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /templates/1
  # DELETE /templates/1.xml
  def destroy
    @template = Template.find(params[:id])
    @template.destroy

    respond_to do |format|
      format.html { render :text=>"<p>Template ##{params[:id]} has been deleted</p>" }
      format.xml  { head :ok }
    end
  end
end
