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
    conversations = Conversation.all
    
    @conversations = []
    conversations.each do |conversation|
      conversation.activity = conversation.activity_count
      @conversations << conversation
    end
  end

  # GET /conversations/1
  def show
    @communities = @conversation.communities
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
      @conversation = Conversation.find(params[:id])
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
