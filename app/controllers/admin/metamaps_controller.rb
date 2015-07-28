# encoding: utf-8

class Admin::MetamapsController < ApplicationController
  
	layout "admin"
  append_before_action :authenticate_participant!

  def search
    @heading = 'Metamaps'
    @sort = ['id desc','','name']
  end  
  
  def index
    metamap_id = params[:metamap_id].to_i

    @per_page = (params[:per_page] || 30).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    sort1 = (params[:sort1] || 'id desc').to_s
    sort2 = params[:sort2].to_s    
    xorder = sort1
    xorder += "," if xorder!="" and sort2!=""
    xorder += sort2 if sort2!=""

    xcond = "1=1"

    if metamap_id>0
      @metamaps = [Metamap.find(metamap_id)]
    else  
      @metamaps = Metamap.where(xcond).order(xorder).paginate(:page=>@page, :per_page => @per_page)    
    end
    
    respond_to do |format|
      format.html { render :partial=>'list', :layout=>false }
      format.xml  { render :xml => @metamaps }
    end
  end

  def show
    @metamap = Metamap.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'show', :layout=>false }
      format.xml  { render :xml => @metamap }
    end
  end

  def new
    @metamap = Metamap.new
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @metamap }
    end
  end

  # GET /hubs/1/edit
  def edit
    @metamap = Metamap.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @metamap }
    end
  end

  # POST /hubs
  # POST /hubs.xml
  def create
    @metamap = Metamap.new(metamap_params)

    respond_to do |format|
      if @metamap.save
        format.html { render :partial=>'show', :layout=>false, :notice => 'Metamap was successfully created.' }
        format.xml  { render :xml => @metamap, :status => :created, :location => @metamap }
      else
        format.html { render :partial=>'edit', :layout=>false }
        format.xml  { render :xml => @metamap.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /hubs/1
  # PUT /hubs/1.xml
  def update
    @metamap = Metamap.find(params[:id])

    respond_to do |format|
      if @metamap.update_attributes(metamap_params)
        format.html { render :partial=>'show', :layout=>false, :notice => 'Metamap was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :partial => "edit", :layout=>false }
        format.xml  { render :xml => @metamap.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /hubs/1
  # DELETE /hubs/1.xml
  def destroy
    @metamap = Metamap.find(params[:id])
    @metamap.destroy

    respond_to do |format|
      format.html { render :text=>"<p>Metamap ##{params[:id]} has been deleted</p>" }
      format.xml  { head :ok }
    end
  end
  
  def nodes
    #-- Return a list of the admins for this hub
    @metamap_id = params[:id].to_i

    @metamap_nodes = MetamapNode.where("metamap_id=?", @metamap_id).order("sortorder,name")
    
    render :partial=>"nodes", :layout=>false
  end  
  
  def node_add
    #-- Add a node
    @metamap_id = params[:id].to_i
    @name = params[:name]
    metamap_node = MetamapNode.where(["metamap_id = ? and name = ?", @metamap_id, @name]).first
    if not metamap_node
      metamap_node = MetamapNode.create(:metamap_id => @metamap_id, :name => @name)
    end
    nodes    
  end 
  
  def node_del 
    #-- Delete a node
    @metamap_id = params[:id].to_i
    node_ids = params[:node_ids]
    for node_id in node_ids
      metamap_node = MetamapNode.find_by_id(node_id)
      if metamap_node
        metamap_node.destroy
      end
    end
    admins
  end
  
  def node_edit
    #-- Edit a node
    @metamap_node_id = params[:node_id].to_i
    @metamap_node = MetamapNode.find_by_id(@metamap_node_id)  
    @metamap_id = @metamap_node.metamap_id  
    render :partial=>'node_edit', :layout=>false
  end
  
  def node_save
    @metamap_node_id = params[:node_id].to_i
    @metamap_node = MetamapNode.find_by_id(@metamap_node_id)
    @metamap_id = @metamap_node.metamap_id 
    if @metamap_node.update_attributes(node_params)
      render :partial=>'node_show', :layout=>false, :notice => 'Node was successfully updated.'
    else
      render :partial => "node_edit", :layout=>false
    end  
  end  

  def node_show
    #-- show a node
    @metamap_node_id = params[:node_id].to_i
    @metamap_node = MetamapNode.find_by_id(@metamap_node_id)  
    @metamap_id = @metamap_node.metamap_id  
    render :partial=>'node_show', :layout=>false
  end
  
  protected
  
  def metamap_params
    params.require(:metamap).permit(:name,:global_default,:binary)
  end

  def node_params
    params.require(:metamap_node).permit(:name,:name_as_group,:description,:sortorder,:sumcat,:binary_on)
  end
  
end
