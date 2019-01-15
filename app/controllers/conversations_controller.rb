class ConversationsController < ApplicationController

	layout "front"
  before_action :set_conversation, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user_from_token!, except: [:join, :front, :fronttag]
  before_action :authenticate_participant!, except: [:join, :front, :fronttag]
  before_action :check_is_admin, except: [:index, :join, :front, :fronttag]

  # GET /conversations
  def index
    # Show a list of conversations
    @section = 'conversations'
    @csection = params[:csection].to_s
    @csection = 'my' if @csection == ''
    
    conversations = []
    if @csection == 'my'
      conversations2 = Conversation.all
      for conversation in conversations2
        for com in conversation.communities
          if current_participant.tag_list.include?(com.tagname)
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
      for com in conversation.communities
        if current_participant.tag_list.include?(com.tagname)
          conversation.perspective = com.tagname
          break
        end
      end
      @conversations << conversation
    end
  end

  # GET /conversations/1
  def show
    
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
      if current_participant.tag_list.include?(com.tagname)
        @perspectives[com.tagname] = com.fullname
      end
    end
    
    if @perspectives.length == 0
      @cur_perspective = 'outside'
    elsif @cur_perspective != ''
    elsif @perspectives.length == 1
      @cur_perspective = @perspectives.keys[0]
    else
      @cur_perspective = @perspectives.keys[0]
    end    
    session["cur_perspective_#{@conversation_id}"] = @cur_perspective
  end

  # GET /conversations/new
  def new
    @conversation = Conversation.new
  end

  # GET /conversations/1/edit
  def edit
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_conversation
      @conversation_id = params[:id]
      @conversation = Conversation.find(@conversation_id)
    end

    # Only allow a trusted parameter "white list" through.
    def conversation_params
      params.require(:conversation).permit(:name, :shortname, :description, :front_template)
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