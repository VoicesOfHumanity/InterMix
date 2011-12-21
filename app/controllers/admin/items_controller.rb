# encoding: utf-8

class Admin::ItemsController < ApplicationController

  layout "admin"
	#layout current_participant.sysadmin? ? "admin" : "application"
  before_filter :authenticate_participant!

  def search
    @heading = 'Items'
    @sort = ['id desc','']
  end  

  # GET /items
  # GET /items.xml
  def index
    item_id = params[:item_id].to_i

    @per_page = (params[:per_page] || 30).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    sort1 = (params[:sort1] || 'id desc').to_s
    sort2 = params[:sort2].to_s    
    xorder = sort1
    xorder += "," if xorder!="" and sort2!=""
    xorder += sort2 if sort2!=""
    

    if item_id>0
      @items = [Item.find(item_id,:include=>[:group,:participant,:dialog])]
    else  
      @items = Item.scoped
      @items = @items.tagged_with(params[:tags]) if params[:tags].to_s != ''
      @items = @items.where(:group_id => params[:group_id]) if params[:group_id].to_i > 0
      @items = @items.where(:posted_by => params[:posted_by]) if params[:posted_by].to_i > 0
      @items = @items.where(:is_flagged => true) if params[:is_flagged].to_i == 1
      @items = @items.includes([:group,:participant,:dialog])
      @items = @items.order(xorder)
      
      @items = @items.paginate :page=>@page, :per_page => @per_page    
      
      #@items = @items.paginate :page=>@page, :per_page => @per_page, :conditions=>"#{xcond}", :include=>[:group,:participant], :order=>xorder    
    end
    
    respond_to do |format|
      format.html { render :partial=>'list', :layout=>false }
      format.xml  { render :xml => @items }
    end
  end

  # GET /items/1
  # GET /items/1.xml
  def show
    @item = Item.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'show', :layout=>false }
      format.xml  { render :xml => @item }
    end
  end

  # GET /items/new
  # GET /items/new.xml
  def new
    @item = Item.new
    @item.item_type = 'message'
    @item.posted_by = current_participant.id
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @item }
    end
  end

  # GET /items/1/edit
  def edit
    @item = Item.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @group }
    end
  end

  # POST /items
  # POST /items.xml
  def create
    @item = Item.new(params[:item])
    itemprocess

    respond_to do |format|
      if @item.save
        format.html { render :partial=>'show', :layout=>false, :notice => 'Item was successfully created.' }
        format.xml  { render :xml => @item, :status => :created, :location => @item }
      else
        format.html { render :action => "edit", :layout=>false }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /items/1
  # PUT /items/1.xml
  def update
    @item = Item.find(params[:id])
    itemprocess

    respond_to do |format|
      if @item.update_attributes(params[:item])
        format.html { render :partial=>'show', :layout=>false, :notice => 'Item was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit", :layout=>false }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1
  # DELETE /items/1.xml
  def destroy
    @item = Item.find(params[:id])
    @item.destroy

    respond_to do |format|
      format.html { render :text=>"<p>Item ##{params[:id]} has been deleted</p>" }
      format.xml  { head :ok }
    end
  end
  
  protected 
  
  def itemprocess
    item = {}
    item['ID'] = 
    item['XmlItemType'] = @item.item_type
    item['Sortby1'] = ''
    item['Sortby2'] = ''
    item['Sortby3'] = ''
    item['AuthorName'] = @item.posted_by
    item['DateTimePosted'] = (@item.created_at ? @item.created_at : Time.now).strftime("%Y-%m-%d %H:%M")
    item['Subject'] = @item.subject_id
    item['HtmlBody'] = @item.html_content
    item['WebLinkToOriginal'] = ''
    @item.xml_content = item.to_xml
  end  
    
  
end
