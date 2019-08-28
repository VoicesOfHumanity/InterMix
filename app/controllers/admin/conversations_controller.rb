class Admin::ConversationsController < ApplicationController

	layout "admin"
  append_before_action :authenticate_participant!

  before_action :set_conversation, only: [:show, :edit, :update, :destroy, :communities, :community_add, :community_del]

  def search
    @heading = 'Conversations'
    @sort = ['shortname','']
  end  

  # GET /conversations
  def index
    @conversations = Conversation.all
    
    conversation_id = params[:conversation_id].to_i

    @context = params[:context].to_s
    @per_page = (params[:per_page] || 30).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    sort1 = (params[:sort1] || 'tagname').to_s
    sort2 = params[:sort2].to_s    
    xorder = sort1
    xorder += "," if xorder!="" and sort2!=""
    xorder += sort2 if sort2!=""

    xcond = "1=1"
    if @context != '*'
      xcond = "context='#{@context}'"
    end

    if conversation_id>0
      @conversations = [Conversation.find(conversation_id)]
    else  
      @conversations = Conversation.where(xcond).order(xorder).paginate(:page=>@page, :per_page => @per_page)  
    end
    
    respond_to do |format|
      format.html { render :partial=>'list', :layout=>false }
      format.xml  { render :xml => @conversations }
    end
    
  end

  # GET /conversations/1
  def show
    respond_to do |format|
      format.html { render :partial=>'show', :layout=>false }
      format.xml  { render :xml => @conversation }
    end
  end

  # GET /conversations/new
  def new
    @conversation = Conversation.new
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @community }
    end
  end

  # GET /conversations/1/edit
  def edit
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @community }
    end
  end

  # POST /conversations
  def create
    @conversation = Conversation.new(params[:conversation])
    respond_to do |format|
      if @conversation.save
        format.html { render :partial=>'show', :layout=>false, :notice => 'Conversation was successfully created.' }
        format.xml  { render :xml => @conversation, :status => :created, :location => @community }
      else
        format.html { render :partial=>'edit', :layout=>false }
        format.xml  { render :xml => @conversation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /conversations/1
  def update
    respond_to do |format|
      if @conversation.update_attributes(params[:conversation])
        format.html { render :partial=>'show', :layout=>false, :notice => 'Conversation was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :partial => "edit", :layout=>false }
        format.xml  { render :xml => @Community.errors, :status => :unprocessable_entity }
      end
    end    
  end

  # DELETE /conversations/1
  def destroy
    @conversation.destroy
    respond_to do |format|
      format.html { render plain: "<p>Conversation ##{params[:id]} has been deleted</p>" }
      format.xml  { head :ok }
    end
  end
  
  def communities
    #-- Return a list of the communities in this conversation
    @communities = @conversation.communities
    @allcommunities = Community.where("fullname!=''")
    render :partial=>"communities", :layout=>false
  end  
  
  def community_add
    #-- Add a community to the conversation
    @community_id = params[:community_id]
    conversation_community = ConversationCommunity.where(conversation_id: @conversation_id, community_id: @community_id).first
    if not conversation_community
      conversation_community = ConversationCommunity.create(conversation_id: @conversation_id, community_id: @community_id)
    end
    communities    
  end 
  
  def community_del 
    #-- Remove a community from the conversation
    community_ids = params[:community_ids]
    for community_id in community_ids
      com = ConversationCommunity.where(conversation_id: @conversation.id, community_id: community_id).first
      if com
        com.destroy
      end
    end
    communities
  end
  

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_conversation
      @conversation = Conversation.find(params[:id])
      @conversation_id = @conversation.id
    end

    # Only allow a trusted parameter "white list" through.
    def conversation_params
      params.require(:conversation).permit(:name, :shortname, :description, :front_template)
    end
end
