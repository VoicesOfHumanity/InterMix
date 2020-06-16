class ConversationsController < ApplicationController

	layout "front"
  before_action :set_conversation, only: [:show, :edit, :update, :destroy, :change_perspective]
  before_action :authenticate_user_from_token!, except: [:join, :front, :fronttag]
  before_action :authenticate_participant!, except: [:join, :front, :fronttag]
  before_action :check_is_admin, except: [:index, :join, :front, :fronttag]
  append_before_action :check_required only: :index

  # GET /conversations
  def index
    # Show a list of conversations
    @section = 'conversations'
    @csection = params[:csection].to_s
    @csection = 'my' if @csection == ''
    @sort = params[:sort] || 'activity'
    
    conversations = []
    if @csection == 'my'
      conversations2 = Conversation.all
      for conversation in conversations2
        for com in conversation.communities
          if current_participant.tag_list_downcase.include?(com.tagname.downcase)
            conversations << conversation
            break
          end
        end
      end
    else
      @csection = 'all'
      conversations = Conversation.all
    end
    
    @conversations = []
    conversations.uniq.each do |conversation|
      conversation.activity = conversation.activity_count
      # Pick an appropriate perspective
      perspectives = {}    
      for com in conversation.communities
        if current_participant.tag_list_downcase.include?(com.tagname.downcase)
          perspectives[com.tagname] = com.fullname
          #logger.info("conversations#index user is in :#{com.tagname}")          
        else
          #logger.info("conversations#index user is not in :#{com.tagname}")          
        end
      end
      conversation.perspectives = perspectives
      if perspectives.length == 0
        conversation.perspective = 'outsider'
      elsif session.has_key?("cur_perspective_#{conversation.id}") and session["cur_perspective_#{conversation.id}"] != ''
        conversation.perspective = session["cur_perspective_#{conversation.id}"]
      elsif perspectives.length == 1
        conversation.perspective = perspectives.keys[0]
      else
        conversation.perspective = perspectives.keys[0]
      end
      session["cur_perspective_#{conversation.id}"] = conversation.perspective 
      logger.info("conversations#index conversation #{conversation.shortname} perspectives:#{perspectives} chosen:#{conversation.perspective}")
      
      @conversations << conversation
    end
    
    # sort
    if @sort == 'activity'
      @conversations.sort! { |a,b| b.send(@sort) <=> a.send(@sort) } 
    else
      @conversations.sort! { |a,b| a.send(@sort) <=> b.send(@sort) } 
    end
    
  end

  # GET /conversations/1
  def show
    @section = 'conversations'
    
    # Stuff that's needed because we show the menu from the slider
    @dialog_id = VOH_DISCUSSION_ID
    @dialog = Dialog.includes(:creator).find(@dialog_id)
    @dsection = 'info'
    
    @perspectives = {}
    if params[:perspective].to_s != ''
      @cur_perspective = params[:perspective]
    elsif session.has_key?("cur_perspective_#{@conversation_id}")
      @cur_perspective = session["cur_perspective_#{@conversation_id}"]
    else
      @cur_perspective = ''
    end
    
    @communities = @conversation.communities
    for com in @communities
      if current_participant.tag_list_downcase.include?(com.tagname.downcase)
        @perspectives[com.tagname] = com.fullname
      end
    end
    
    if @perspectives.length == 0
      @cur_perspective = 'outsider'
    elsif @cur_perspective != ''
    elsif @perspectives.length == 1
      @cur_perspective = @perspectives.keys[0]
    else
      @cur_perspective = @perspectives.keys[0]
    end    
    session["cur_perspective_#{@conversation_id}"] = @cur_perspective
    
    # sort communities
    @communities = @communities.to_a
    @communities.sort! do |a, b|
      if b.tagname == @cur_perspective
        1
      elsif b.tagname != @cur_perspective and @perspectives.has_key?(a.tagname)
        -1
      elsif @perspectives.has_key?(b.tagname) and !@perspectives.has_key?(a.tagname)
        1
      elsif @perspectives.has_key?(a.tagname) and !@perspectives.has_key?(b.tagname)
        -1
      else
        a.tagname <=> b.tagname
      end
    end
    
  end

  # GET /conversations/new
  def new
    @conversation = Conversation.new

    # Stuff that's needed because we show the menu from the slider
    @dialog_id = VOH_DISCUSSION_ID
    @dialog = Dialog.includes(:creator).find(@dialog_id)
    @dsection = 'info'
  end

  # GET /conversations/1/edit
  def edit
    @section = 'conversations'

    # Stuff that's needed because we show the menu from the slider
    @dialog_id = VOH_DISCUSSION_ID
    @dialog = Dialog.includes(:creator).find(@dialog_id)
    @dsection = 'edit'
  end

  # POST /conversations
  def create
    @conversation = Conversation.new(conversation_params)

    if @conversation.save
      redirect_to @conversation, notice: 'Conversation was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /conversations/1
  def update
    if @conversation.update(conversation_params)
      redirect_to @conversation, notice: 'Conversation was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /conversations/1
  def destroy
    @conversation.destroy
    redirect_to conversations_url, notice: 'Conversation was successfully destroyed.'
  end
  
  def change_perspective
    # Change the current user's perspective. Called by Ajax
    perspective = params[:perspective].to_s
    com = Community.find_by_tagname(perspective)
    if not com
      render plain: "not found"
    else  
      if current_participant.tag_list_downcase.include?(com.tagname.downcase)
        session["cur_perspective_#{@conversation.id}"] = perspective
        render plain: "ok"
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_conversation
      @conversation_id = params[:id]
      @conversation = Conversation.find(@conversation_id)
    end

    # Only allow a trusted parameter "white list" through.
    def conversation_params
      params.require(:conversation).permit(:name, :shortname, :description, :front_template, :together_apart)
    end
    
    def check_is_admin
      @conversation_id = params[:id].to_i
      @is_admin = false
      @is_super = false
      @is_moderator = false
      if current_participant.sysadmin
        @is_admin = true
        @is_super = true
      else
        #admin = CommunityAdmin.where(["community_id = ? and participant_id = ?", @community_id, current_participant.id]).first
        #if admin
        #  @is_admin = true
        #  @is_moderator = true
        #end
      end
    end
    
end
