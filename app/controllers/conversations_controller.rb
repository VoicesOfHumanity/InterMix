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
          if conversation.context == 'gender'
            if current_participant.gender_id == com.context_code.to_i
              conversations << conversation
              break
            end
          elsif conversation.context == 'generation'
            if current_participant.generation_id == com.context_code.to_i
              conversations << conversation
              break
            end
          end
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
        if conversation.context == 'gender' and current_participant.gender_id == com.context_code.to_i
          perspectives[com.tagname] = com.fullname
        elsif conversation.context == 'generation' and current_participant.generation_id == com.context_code.to_i
          perspectives[com.tagname] = com.fullname
        elsif current_participant.tag_list_downcase.include?(com.tagname.downcase)
          perspectives[com.tagname] = com.fullname
          #logger.info("conversations#index user is in :#{com.tagname}")          
        else
          #logger.info("conversations#index user is not in :#{com.tagname}")          
        end
      end
      conversation.perspectives = perspectives
      if perspectives.length == 0
        conversation.perspective = 'outsider'
        #logger.info("conversations#index no perspectives, so choosing outsider")
      elsif perspectives.length == 1
        conversation.perspective = perspectives.keys[0]
        #logger.info("conversations#index choosing the only perspective: #{conversation.perspective}")
      elsif session.has_key?("cur_perspective_#{conversation.id}") and session["cur_perspective_#{conversation.id}"] != '' and session["cur_perspective_#{conversation.id}"] != 'outsider'
        conversation.perspective = session["cur_perspective_#{conversation.id}"]
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
    elsif @conversation.id == INT_CONVERSATION_ID
      @prof_nations = []  
      communities = []
      got_com = {}
      coms = @conversation.communities
      logger.info("conversations#show #{coms.length} communities total")
      iso1 = nil
      iso2 = nil
      if current_participant.country_code != ''
        country1 = Geocountry.where(iso: current_participant.country_code).first
        if country1
          iso1 = country1.iso3
        end
      end
      has_indig = false
      if current_participant.country_code2 == '_I'
        iso2 = '__I'
        has_indig = true
      elsif current_participant.country_code2 != ''
        country2 = Geocountry.where(iso: current_participant.country_code2).first
        if country2
          iso2 = country2.iso3
        end
      end
      if iso2 and iso2 != '__I'
        # check if they have Indigenous religion
        r = Religion.where(shortname: 'Indigenous').first
        if r
          p_r = ParticipantReligion.where(participant_id: current_participant.id, religion_id: r.id).first
          if p_r
            has_indig = true
          end
        end
      end
      for com in coms
        if (com.context_code == '__I' and has_indig) or (iso1 and (com.context_code == iso1 or com.context_code2 == iso1)) or (iso2 and (com.context_code == iso2 or com.context_code2 == iso2))
          com.activity = com.activity_count
          @prof_nations << com
          @cur_perspective = com.tagname
          @perspectives[com.tagname] = com.fullname
        else
          if not got_com.has_key?(com.tagname)
            communities << com
            got_com[com.tagname] = true
          end
        end
      end
      @communities = communities
    elsif @conversation.id == RELIGIONS_CONVERSATION_ID
      @prof_religions = []
      communities = []
      got_com = {}
      coms = @conversation.communities
      logger.info("conversations#show #{coms.length} communities total")
      for com in coms
        if com.context == 'religion'
          r_id = com.context_code.to_i
        elsif com.context2 == 'religion'
          r_id = com.context_code2.to_i
        else
          r_id = nil
        end
        if r_id and ParticipantReligion.where(religion_id: r_id, participant_id: current_participant.id).count > 0
          com.activity = com.activity_count
          @prof_religions << com
          @cur_perspective = com.tagname
          @perspectives[com.tagname] = com.fullname
        else
          if not got_com.has_key?(com.tagname)
            communities << com
            got_com[com.tagname] = true
          end
        end
      end
      @communities = communities
    elsif @conversation.id == GENDER_CONVERSATION_ID
      # find the community that goes with their gender
      @perspectives = {}
      com = Community.where(context: 'gender', context_code: current_participant.gender_id).first
      if com
        @cur_perspective = com.tagname
        @perspectives[com.tagname] = com.fullname
      end
      @communities = @conversation.communities 
    elsif @conversation.id == GENERATION_CONVERSATION_ID
      # find the community that goes with their generation
      @perspectives = {}
      com = Community.where(context: 'generation', context_code: current_participant.generation_id).first
      if com
        @cur_perspective = com.tagname
        @perspectives[com.tagname] = com.fullname
      end      
      @communities = @conversation.communities 
    else
      @communities = @conversation.communities      
    end
    
    if @conversation.id != CITY_CONVERSATION_ID and @conversation.id != RELIGIONS_CONVERSATION_ID and @conversation.id != INT_CONVERSATION_ID
      for com in @communities
        if current_participant.tag_list_downcase.include?(com.tagname.downcase)
          @perspectives[com.tagname] = com.fullname
        end
      end
    end
    
    logger.info("conversations#show #{@perspectives.length} perspectives")
    
    if @perspectives.length == 0
      @cur_perspective = 'outsider'
    elsif @cur_perspective != '' and @cur_perspective != 'outsider'
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
    
    @comtag = @cur_perspective
        
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

  def get_default
    #-- Return a particular default template, e.g. invite, member, import
    which = params[:which]
    render :partial=>"#{which}_default", :layout=>false
  end

  def test_template
    #-- Show a template with the liquid macros filled in
    which = params[:which]
    @conversation_id = params[:id].to_i
    @conversation = Conversation.find_by_id(@conversation_id)
    #@logo = @conversation.logo.exists? ? "https://#{BASEDOMAIN}#{@conversation.logo.url}" : "" 
    @participant = current_participant
    @email = @participant.email
    @name = @participant.name
    
    cdata = {}
    cdata['conversation'] = @conversation
    cdata['conversation_logo'] = @logo
    cdata['participant'] = @participant
    cdata['current_participant'] = @current_participant
    cdata['recipient'] = @participant
    cdata['password'] = '[#@$#$%$^]'
    #cdata['logo'] = @logo
      
    if @conversation.send("#{which}_template").to_s != ""
      template_content = render_to_string(plain: @conversation.send("#{which}_template"), layout: false)
    else
      template_content = render_to_string(:partial=>"#{which}_default",:layout=>false)
    end      
    template = Liquid::Template.parse(template_content)
    render html: template.render(cdata).html_safe, layout: false
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
