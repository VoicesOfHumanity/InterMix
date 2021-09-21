class ConversationsController < ApplicationController

	layout "front"
  before_action :set_conversation, only: [:show, :edit, :update, :destroy, :change_perspective, :top_posts]
  before_action :authenticate_user_from_token!, except: [:join, :front, :fronttag]
  before_action :authenticate_participant!, except: [:join, :front, :fronttag]
  before_action :check_is_admin, except: [:index, :join, :front, :fronttag]

  def fronttag
    #-- Show the public front page
    #-- http://voh.intermix.cr8.com/conversation/IPpeace
    tagname = params[:tagname].to_s

    @conversation = Conversation.find_by_shortname(tagname)
    if not @conversation
      redirect_to "/"
      return
    end
   
    if participant_signed_in?
      redirect_to "/conversations/#{@conversation.id}"
      return
    end
    
    session[:sawconvfront] = 'yes'
    session[:previous_convtag] = tagname
    
    @dialog_id = VOH_DISCUSSION_ID
    @cdata = {}
    @cdata['conversation'] = @conversation
    if @conversation.front_template.to_s.strip != ''
      desc = Liquid::Template.parse(@conversation.front_template).render(@cdata)
    else   
      tcontent = render_to_string :partial=>"conversations/front_default", :layout=>false
      desc = Liquid::Template.parse(tcontent).render(@cdata)
    end
    @content = "<div>#{desc}</div>"    
    render action: :front    
  end


  # GET /conversations
  def index
    # Show a list of conversations

    #@section = 'conversations'
    @section = 'communities'
    @csection = params[:csection].to_s
    if @csection == ''
      if current_participant.status == 'visitor'
        @csection = 'all'
      else  
        @csection = 'my'
      end 
    end
        
    @sort = params[:sort] || 'activity'
    
    @cur_period = get_current_conv_period
    
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
      conversation.activity = conversation.activity_count(@cur_period)
      
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
    if @conversation.id == INT_CONVERSATION_ID
      @section = 'nations'
    elsif @conversation.id == CITY_CONVERSATION_ID
      @section = 'cities'
    elsif @conversation.id == UNGOALS_CONVERSATION_ID
      @section = 'ungoals'
    else
      @section = 'conversations'
    end

    @in = 'conversation'
    
    # Stuff that's needed because we show the menu from the slider
    @dialog_id = VOH_DISCUSSION_ID
    @dialog = Dialog.includes(:creator).find(@dialog_id)
    @dsection = 'info'
    
    @cur_period = get_current_conv_period
        
    @perspectives = {}
    if params[:perspective].to_s != ''
      @cur_perspective = params[:perspective]
    elsif session.has_key?("cur_perspective_#{@conversation_id}") and @conversation.id != CITY_CONVERSATION_ID
      @cur_perspective = session["cur_perspective_#{@conversation_id}"]
    else
      @cur_perspective = ''
    end
    
    if @conversation.id == CITY_CONVERSATION_ID  
      if current_participant.city_uniq.to_s != ''
        @perspective = 'outsider'
        for com in @conversation.communities
          if com.context_code == current_participant.city_uniq
            @perspective = com.tagname
            @perspectives = {com.tagname => com.fullname}
          end
        end
      end
      @prof_cities = []
      communities = []
      got_com = {}
      coms = @conversation.communities
      logger.info("conversations#show #{coms.length} communities total")
      for com in coms
        if current_participant.city_uniq != '' and com.context_code == current_participant.city_uniq
          com.activity = com.activity_count
          @prof_cities << com
          @cur_perspective = com.tagname
          logger.info("conversations#show adding #{com.tagname} to prof_cities")
        else
          if not got_com.has_key?(com.tagname)
            communities << com
            got_com[com.tagname] = true
          end
        end
      end
      @communities = communities
    else
      @communities = @conversation.communities      
    end
    
    if @conversation.id != CITY_CONVERSATION_ID
      for com in @communities
        if current_participant.tag_list_downcase.include?(com.tagname.downcase)
          @perspectives[com.tagname] = com.fullname
        end
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
    if @conversation.id == CITY_CONVERSATION_ID
      @communities.sort! { |a,b| [b.send('activity'),a.send('tagname')] <=> [a.send('activity'),b.send('tagname')] }
      @communities = @communities[0..20]
    elsif @conversation.context == 'twocountry' or @conversation.twocountry
      sorder = {
        @conversation.twocountry_common => 1,
        @conversation.twocountry_country1 => 2,
        @conversation.twocountry_country2 => 3,
        @conversation.twocountry_supporter1 => 4,
        @conversation.twocountry_supporter2 => 5
      }
      @communities.sort! do |a,b| 
        sorder[a.id] <=> sorder[b.id]
      end
    else
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
    if @conversation.id == INT_CONVERSATION_ID
      @section = 'nations'
    elsif @conversation.id == CITY_CONVERSATION_ID
      @section = 'cities'
    elsif @conversation.id == UNGOALS_CONVERSATION_ID
      @section = 'ungoals'
    else
      @section = 'conversations'
    end
    @in = 'conversation'

    # Stuff that's needed because we show the menu from the slider
    @dialog_id = VOH_DISCUSSION_ID
    @dialog = Dialog.includes(:creator).find(@dialog_id)
    @dsection = 'edit'
  end

  # POST /conversations
  def create
    @conversation = Conversation.new(conversation_params)

    if @conversation.save
      
      if params[:topic_list]
        topic_list = params[:topic_list]
        @conversation.topics_will_change!
        @conversation.topics = topic_list.split(', ')
        @conversation.save
      end
      
      redirect_to @conversation, notice: 'Conversation was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /conversations/1
  def update
    if @conversation.update(conversation_params)
      
      if params[:topic_list]
        topic_list = params[:topic_list]
        @conversation.topics_will_change!
        @conversation.topics = topic_list.split(', ')
        @conversation.save
      end
      
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
  
  def top_posts
    @section = 'conversations'
    
    # Stuff that's needed because we show the menu from the slider
    @dialog_id = VOH_DISCUSSION_ID
    @dialog = Dialog.includes(:creator).find(@dialog_id)
    @dsection = 'info'
    
    @conversations.communities.each do |com|
      
      
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
      params.require(:conversation).permit(:name, :shortname, :description, :front_template, :together_apart, :active, :default_topic)
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
    
    def get_current_conv_period
      @cur_period = ""
      @cur_moon_new_new = session[:cur_moon_new_new]
      @cur_moon_full_full = session[:cur_moon_full_full]
      @cur_moon_new_full = session[:cur_moon_new_full]
      @cur_moon_full_new = session[:cur_moon_full_new]
      if @cur_moon_new_full.to_s != ''
        @cur_period = @cur_moon_new_full
      elsif @cur_moon_full_new.to_s != ''
        @cur_period = @cur_moon_full_new
      end
      return @cur_period
    end
    
end
