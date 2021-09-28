require 'will_paginate/array'

class DialogsController < ApplicationController

	layout "front"
  append_before_action :authenticate_user_from_token!
  append_before_action :authenticate_participant!, :except => :previous_result
  append_before_action :get_group_dialog_from_subdomain, :check_group_and_dialog, :check_status, :except => :previous_result
  append_before_action :redirect_subdom, :except => :index
  append_before_action :check_required, only: :slider

  def index
    #-- Show an overview of dialogs this person has access to
    @section = 'dialogs'
    @dsection = 'index'
    if false
      @gpin = GroupParticipant.where("participant_id=#{current_participant.id}").select("distinct(group_id)").includes(:group)
      @groupsina = @gpin.collect{|g| g.group.id}      
      @dialogsin = []   # All dialogs they're in
      @dialogsingroup = []   # Dialogs for the current group, if any
      ddone1 = {}
      ddone2 = {}
      for gp in @gpin
        gdialogsin = DialogGroup.where("group_id=#{gp.group.id}").includes(:dialog)
        for gd in gdialogsin
          if not ddone1[gd.dialog.id]
            @dialogsin << gd.dialog
            ddone1[gd.dialog.id] = true
          end  
          if not ddone2[gd.dialog.id] and session[:group_id].to_i > 0 and gp.group_id == session[:group_id].to_i
            @dialogsingroup << gd.dialog
            ddone2[gd.dialog.id] = true
          end
        end  
      end  
    else
      #-- We now no longer care if they're a member. Just list dialogs for the last group looked at.
      if session[:group_id].to_i > 0
        @group = Group.includes(:dialogs).find(session[:group_id])
      end  
    end
    
    #-- See if they're a moderator of a group, or a hub admin. Only those can add new discussions.
    groupsmodof = GroupParticipant.where("participant_id=#{current_participant.id} and moderator=1")
    @is_group_moderator = (groupsmodof.length > 0)
    hubadmins = HubAdmin.where("participant_id=#{current_participant.id} and active=1")
    @is_hub_admin = (hubadmins.length > 0)
    
    @admin4 = DialogAdmin.where("participant_id=?",current_participant.id).collect{|r| r.dialog_id}
    
    update_last_url
    update_prefix
  end  
  
  def slider
    #-- This is when we go to dialogs/x/slider. Not when we move between tabs or change options
    #-- It might be clicking one of: Order out of Chaos, Conversation forum, or Community forum
    
    return if redirect_if_not_voh
    logger.info("dialogs#slider")
    @dsection = 'slider'
    @dialog_id = VOH_DISCUSSION_ID
    @dialog = Dialog.includes(:creator).find(@dialog_id)
    @show_result = params[:show_result].to_i
    @top_posts = params[:top_posts].to_i
    @network_id = params[:network_id].to_i
    @period = params[:period].to_s    # Mostly matches datefixed, but not quite. To control the period, particularly for linking to results
    @topic = params[:topic].to_s
    logger.info("dialogs#slider topic:#{@topic}")
    
    @cur_moon_new_new = session[:cur_moon_new_new]
    @cur_moon_full_full = session[:cur_moon_full_full]
    @cur_moon_new_full = session[:cur_moon_new_full]
    @cur_moon_full_new = session[:cur_moon_full_new]
    @cur_half_moon = session[:cur_half_moon]
    
    comtag_before = session.has_key?(:comtag) ? session[:comtag] : ''

    @conv = ''
    @comtag = ''
    
    #-- Special case for communities
    #if params.has_key?(:comtag) and not params.has_key?(:conv)
    #  #-- Send them to Conversation forum if the user is a member and the community is a member of just one conversation
    #  #-- Seems like a bad idea, but OK
    #  @comtag = params[:comtag]
    #  if @comtag != '' and @comtag != '-'
    #    @community = Community.find_by_tagname(@comtag)
    #    @community_id = @community.id      
    #  end    
    #  if @community.conversations.length == 1 and current_participant.tag_list.include?(@community.tagname)
    #    conversation = @community.conversations[0]
    #    redirect_to "/dialogs/#{VOH_DISCUSSION_ID}/slider?conv=#{conversation.shortname}&comtag=#{@community.tagname}"
    #    return
    #  end
    #end
    #-----

    if params.has_key?(:conv)
      @in = 'conversation'
      @conv = params[:conv]
      if @conv == INT_CONVERSATION_CODE
        @section = 'nations'
      elsif @conv == CITY_CONVERSATION_CODE
        @section = 'cities'
      elsif @conv == UNGOALS_CONVERSATION_CODE
        @section = 'ungoals'
      else
        @section = 'conversations'
      end
      if params.has_key?(:comtag)
        # might be a - to leave the conversation
        @comtag = params[:comtag]
        logger.info()
      else
        @comtag = ''
      end
      # Conversations should have conv and comtag specifed in the URL. At first there might only be a conv and no comtag
      logger.info("dialogs#slider in conversation #{@conv} comtag:#{@comtag}")
    elsif params.has_key?(:network_id)
      @in = 'network'
      @section = 'communities'      
      @network_id = params[:network_id]
      logger.info("dialogs#slider in network ##{@network_id} under communities")
    elsif params.has_key?(:comtag)
      @in = 'community'
      @section = 'communities'
      @comtag = params[:comtag]
      # Communities should have comtag specified in the url
      logger.info("dialogs#slider in community #{@comtag}")
    else
      @in = 'main'
      @section = 'home'
      # There should be neither conversation nor community mentioned in the url. Comtag might later be selected as an option within the main forum.
      logger.info("dialogs#slider in main")
    end

    if @top_posts == 1
      @dsection = 'top'
    elsif @show_result == 1
      @dsection = 'meta'
    else
      @dsection = 'list'
    end

    if not params.has_key?(:show_result)
      # all movement between tabs keeps the show_result parameter. If it isn't there, we're coming here from elsewhere
      is_new = true
    else
      is_new = false
    end
    @is_first = is_new
    
    # Certain things might be remembered as a cookie, when we move between tabs, but should be reset if we go to another section:
    # comtag (only in main forum)
    # messtag (don't use in conversation)
    # nvaction
    # geo_level
    # gender?
    # age?
    # -datetype
    # datefixed
    # -datefrom
    # sortby
    # threads
  
    # defaults
    @geo_level = 6
    @nvaction = false
    @include_nvaction = false
    @messtag = ''
    @datetype = 'fixed'
    @datefixed = 'month'
    logger.info("dialogs#slider datefixed initial default: #{@datefixed}")
    if @in == 'conversation'
      logger.info("dialogs#slider @cur_moon_new_full:#{@cur_moon_new_full} @cur_moon_full_new:#{@cur_moon_full_new}")
      if @cur_moon_new_full.to_s != ''
        @datefixed = @cur_moon_new_full
        logger.info("dialogs#slider datefixed set to #{@cur_moon_new_full} based on @cur_moon_new_full")
      elsif @cur_moon_full_new.to_s != ''
        @datefixed = @cur_moon_full_new
        logger.info("dialogs#slider datefixed set to #{@cur_moon_full_new} based on @cur_moon_full_new")
      else
        logger.info("dialogs#slider neither @cur_moon_new_full nor @cur_moon_full_new are set")
      end
    end
    @defaultdatefixed = @datefixed
    
    #@datefrom = (Date.today-364).beginning_of_month.strftime('%Y-%m-%d')
    @sortby = (@in == 'main' ? 'items.id desc' : '*value*')
    @threads = 'flat'
    @perspective = ''
      
    if is_new
      # First time here, reset some options
      session.delete(:conv)
      session.delete(:comtag) if @in == 'main'
      session.delete(:messtag)
      session.delete(:nvaction)
      session.delete(:geo_level)
      session.delete(:age)
      session.delete(:gender)
      session.delete(:datetype)
      #session.delete(:datefixed)
      session.delete(:datefrom)
      session.delete(:list_threads)
      session.delete(:list_sortby)
    else
      # We're just moving between tabs. Remember the options
      @geo_level = session[:geo_level] if session[:geo_level].to_i > 0
      @comtag = session[:comtag].to_s if session.has_key?(:comtag) and @in == 'main' and @comtag == ''
      @messtag = session[:messtag].to_s if session.has_key?(:messtag)
      @nvaction = session[:nvaction] if session.has_key?(:nvaction)
      #@datetype = session[:datetype] if session.has_key?(:datetype)
      #@datefrom = session[:datefrom] if session.has_key?(:datefrom)
      @sortby = session[:list_sortby] if session.has_key?(:list_sortby)
      @threads = session[:list_threads] if session.has_key?(:list_threads)
    end

    if @in == 'conversation' and session.has_key?(:datefixed_conversation)
      @datefixed = session[:datefixed_conversation]
      logger.info("dialogs#slider datefixed set from session[:datefixed_conversation] to: #{@datefixed}")
    elsif @in == 'community' and session.has_key?(:datefixed_community)
      @datefixed = session[:datefixed_community]
      logger.info("dialogs#slider datefixed set from session[:datefixed_community] to: #{@datefixed}")
    elsif session.has_key?(:datefixed)
      @datefixed = session[:datefixed]
      logger.info("dialogs#slider datefixed set from session[:datefixed] to: #{@datefixed}")
    end

    # We might have gotten specific parameters, which override defaults and session variables
    # Note: conv and comtag were handled at the top
    if params.has_key?(:messtag)
      @messtag = params[:messtag].to_s     
    elsif params.has_key?(:comtag) and @comtag != '' and (@in == 'main' or @in == 'community') and not params.has_key?(:show_result)
      #-- If they clicked on a community tag link, select the message tag too
      @messtag = @comtag
      logger.info("dialogs#slider @messtag set to the same as @comtag")
    end
    if params.has_key?(:nvaction)
      @nvaction = (params[:nvaction].to_i == 1) ? true : false
    end
    
    if @period.to_s != ""
      # Override the period based on a parameter. Mostly used for results
      if @period == 'cur_moon'
        if @cur_moon_new_full.to_s != ''
          @datefixed = @cur_moon_new_full
        elsif @cur_moon_full_new.to_s != ''
          @datefixed = @cur_moon_full_new
        end        
        logger.info("dialogs#slider datefixed set to #{@datefixed} as cur_moon")
      elsif @period == 'recent_moon'
        # We might not need that after all
        # 2020-10-16_2020-10-31        
      elsif ['day', 'week', 'month', 'year', 'all'].include? @period 
        @datefixed = @period
      else
        @datefixed = @period
        logger.info("dialogs#slider datefixed set to #{@datefixed} literally")
      end
    end
    
    # Remember our current settings, mainly for going back and forth between tabs
    session[:conv] = @conv
    session[:comtag] = @comtag
    session[:messtag] = @messtag
    session[:nvaction] = @nvaction
    session[:geo_level] = @geo_level
    #session[:datetype] = @datetype
    session[:datefixed] = @datefixed
    logger.info("dialogs#slider session[:datefixed] set to #{@datefixed}")
    if @in == 'conversation'
      session[:datefixed_conversation] = @datefixed
      logger.info("dialogs#slider session[:datefixed_conversation] set to #{@datefixed}")
    elsif @in == 'community'
       session[:datefixed_community] = @datefixed
       logger.info("dialogs#slider session[:datefixed_community] set to #{@datefixed}")
    end
    
    #session[:datefrom] = @datefrom
    session[:list_sortby] = @sortby
    session[:list_threads] = @threads

    # Get some objects we might need
    if @comtag != '' and @comtag != '-' and not @community
      @community = Community.find_by_tagname(@comtag)
      @community_id = @community.id if @community    
    end    
    @conversations = []
    #if @community
    #  @conversations = @community.conversations
    #end
    if @in == 'conversation'
      # Which conversations does this use have access to, through any community
      conv_done = {}
      for conv in Conversation.all
        for com in conv.communities
          if current_participant.tag_list_downcase.include?(com.tagname.downcase)
            if not conv_done.has_key?(conv.shortname)
              @conversations << conv
              conv_done[conv.shortname] = true
            end
          end
        end
      end
      # There are no message tags in conversations
      @messtag = ''
    end
    if @conv != '' and @conv != '-'
      @conversation = Conversation.find_by_shortname(@conv)
      @conversation_id = @conversation ? @conversation.id : 0
      if @conversation_id == CITY_CONVERSATION_ID 
        @geo_level = 1
      end      
    end
    
    if @in == 'conversation' and @conversation and @conversation.id == INT_CONVERSATION_ID
      #-- If we're going to the international conversation, make sure they're a member of their country communities
      country1 = nil
      country2 = nil
      country1_tag = ''
      country2_tag = ''
      if current_participant.country_code and current_participant.country_code.to_s != ''
        country1 = Geocountry.where(iso: current_participant.country_code).first
      end
      if not country1 and current_participant.country_name and current_participant.country_name.to_s != ''
        country1 = Geocountry.where(name: current_participant.country_name).first
      end
      if country1
        community = Community.where(context: 'nation', context_code: country1.iso3).first
        if community
          country1_tag = community.tagname
          if not current_participant.tag_list_downcase.include?(community.tagname.downcase)
            current_participant.tag_list.add(country1_tag)
            current_participant.save!
          end
        else
          logger.info("dialogs#slider nation community #{country1.iso3} not found")
        end
      end

      if current_participant.country_code2.to_s == '_I'
        country2_tag = 'indigenous'
        if not current_participant.tag_list_downcase.include?('indigenous')
          current_participant.country_name2 = "Indigenous peoples"
          current_participant.tag_list.add("indigenous")
          current_participant.save!     
        end
      else
        if current_participant.country_code2 and current_participant.country_code2.to_s != ''
          country2 = Geocountry.where(iso: current_participant.country_code2).first
        end
        if not country2 and current_participant.country_name2 and current_participant.country_name2.to_s != ''
          country2 = Geocountry.where(name: current_participant.country_name2).first
        end
        if country2
          community = Community.where(context: 'nation', context_code: country2.iso3).first
          if community
            country2_tag = community.tagname
            if not current_participant.tag_list_downcase.include?(community.tagname.downcase)
              current_participant.tag_list.add(country2_tag)
              current_participant.save!
            end
          else
            logger.info("dialogs#slider nation community #{country2.iso3} not found")
          end
        end
      end
      
      was_comtag = @comtag
      if @comtag != '' and @comtag == country1_tag
        @perspective = @comtag
        logger.info("dialogs#slider perspective set to #{@perspective} in international conversation, from @comtag, same as country1")
      elsif @comtag != '' and @comtag == country2_tag
        @perspective = @comtag
        logger.info("dialogs#slider perspective set to #{@perspective} in international conversation, from @comtag, same as country2")
      else
        @comtag = country1_tag
        @perspective = @comtag
        logger.info("dialogs#slider perspective set to #{@perspective} (country1) in international conversation, because it was something else (#{was_comtag}). Redirecting.")
        if @comtag != was_comtag
          url = "/dialogs/#{@dialog_id}/slider?comtag=#{@comtag}&conv=#{@conversation.shortname}"
          url += "&show_result=1" if @show_result == 1
          redirect_to url
          return
        end
      end
      session["cur_perspective_#{@conversation.id}"] = @perspective
      @is_conv_member = true

    elsif @in == 'conversation' and @conversation and @conversation.id == CITY_CONVERSATION_ID
        #-- If we're going to the city conversation, send them to their profile if they don't have one   
        if current_participant.city_uniq.to_s == ''   
          flash.alert = "You must provide your city to take part in The Cities conversation. To select a city you may need to provide your Province or State."
          url = "/me/profile/edit"
          redirect_to url
          return
        end
        
    elsif @in == 'conversation' and @conversation and @conversation.id == ISRAEL_PALESTINE_CONV_ID
      # Not sure if we need to do anything special
        
    end
    
    @communities = []
    if @conversation
      # If the user is in several communities in the conversation
      for com in @conversation.communities
        if current_participant.tag_list_downcase.include?(com.tagname.downcase)
          @communities << com
        end
      end  
      @include_nvaction = (@conversation.together_apart == 'apart' ? true : false)
    end
    @perspectives = @communities
    @community_list = @communities.collect{|c| [c.fullname,c.tagname]}
    session['community_list'] = @community_list
    
    if @network_id.to_i > 0
      @network = Network.find_by_id(@network_id)
    end
    
    if @in == 'community'
      #-- In a community, they maybe need to join
      if (@comtag != '' and params.has_key?(:joincom)) or (session.has_key?(:joincom))
        # They should be joined to the community, if they aren't already a member ?comtag=love&joincom=1
        if session.has_key?(:joincom)
          @comtag = comtag_before
        end
        comtag = @comtag
        comtag.gsub!(/[^0-9A-za-z_]/,'')
        #comtag.downcase!
        if ['VoiceOfMen','VoiceOfWomen','VoiceOfYouth','VoiceOfExperience','VoiceOfExperie','VoiceOfWisdom'].include? comtag
        elsif comtag != ''
          current_participant.tag_list.add(comtag)
        end
        current_participant.save
        @messtag = @comtag
        session[:messtag] = @messtag
        session[:comtag] = @comtag
        session.delete(:joincom)
      end

      # Do we want to send them to a conversation, if they have only community specified? 
      # Change of policy, now we don't do that any longer. We catch it in the listing of communities.
      if false and not @conversation and @community and current_participant.tag_list.include?(@comtag)
        # If we're in a community, and the user is a member. Conversation not specified. Figure out which one
        if @community.conversations.length == 1
          # Community is in only one conversation, go there
          @conversation = @community.conversations[0]
          url = "/dialogs/#{@dialog_id}/slider?comtag=#{@comtag}&conv=#{@conversation.shortname}"
          url += "&show_result=1" if @show_result == 1
          redirect_to url
          return
        elsif @community.conversations.length > 1
          # Community is in more than one conversation. Pick the last one.
          @conversation = @community.conversations.last
          url = "/dialogs/#{@dialog_id}/slider?comtag=#{@comtag}&conv=#{@conversation.shortname}"
          url += "&show_result=1" if @show_result == 1
          redirect_to url
          return
        end
      end
      
    elsif @in == 'conversation' and @conv == '-'
      #-- They want to leave the conversation, i.e. leave conversation mode
      if @comtag != ''
        #-- Go to that community
        url = "/dialogs/#{@dialog_id}/slider?comtag=#{@comtag}"
      else
        #-- Go to order out of chaos
        url = "/dialogs/#{@dialog_id}/slider"        
      end
      redirect_to url
      return      
      
    elsif @in == 'conversation' and current_participant.status == 'visitor'
      @perspective = 'visitor'
      
    elsif @in == 'conversation' and @conv != '-' and @conversation and @conversation.id != INT_CONVERSATION_ID
      #-- In a conversation, they also need a community/perspective, if there is a suitable one      
      logger.info("dialogs#slider check for conversation perspective")
      @perspective = ''
      @is_conv_member = false
      if @comtag == ""
        # Does the user already have a reasonable perspective?
        if @conversation.id == CITY_CONVERSATION_ID and current_participant.city_uniq.to_s != ''
          @perspective = 'outsider'
          for com in @perspectives
            if com.context_code == current_participant.city_uniq
              @perspective = com.tagname
              @perspectives = [com]
              @comtag = @perspective
            end
          end
          logger.info("dialogs#slider city perspective: #{@perspective} comtag: #{@comtag}")
        elsif @perspectives.length == 1 and @conversation.id != CITY_CONVERSATION_ID
            #@comtag = @perspectives.keys[0]
            @comtag = @perspectives[0].tagname
            logger.info("dialogs#slider perspective from only available: #{@comtag} for #{@conversation.shortname}")
        elsif @perspectives.length == 0
          @perspective = 'outsider'
        elsif session.has_key?("cur_perspective_#{@conversation.id}") and session["cur_perspective_#{@conversation.id}"] != '' and @conversation.id != CITY_CONVERSATION_ID and @conversation.context != 'twocountry' and session["cur_perspective_#{@conversation.id}"] != 'outsider'
          @comtag = session["cur_perspective_#{@conversation.id}"]
          logger.info("dialogs#slider perspective from cookie: #{@comtag} for #{@conversation.shortname}")
        elsif @conversation.id == ISRAEL_PALESTINE_CONV_ID
          # pick one of the countries, if we have them and if member of both, pick Palestine
          @comtag = ''
          for pcom in @perspectives
            if pcom.tagname == 'Israel' and @comtag == ''
              @comtag = pcom.tagname
            elsif pcom.tagname[0..5] == 'Palest'
              @comtag = pcom.tagname
            end
          end
          if @comtag
            # We got a country
            logger.info("dialogs#slider perspective set to country: #{@comtag} for #{@conversation.shortname}")
            # Get rid of any membership of the supporter communities, if they exist
            for pcom in @perspectives
              if pcom.id == @conversation.twocountry_supporter1 or pcom.id == @conversation.twocountry_supporter2
                @perspectives.delete(pcom)
                current_participant.tag_list.remove(pcom.tagname)
                current_participant.save
              end
            end
          else
            # if we don't have any of the two countries, pick something else
            @comtag = @perspectives[0].tagname
            logger.info("dialogs#slider perspective from first in the list: #{@comtag} for #{@conversation.shortname}, as there weren't any countries")
          end       
        else
          #@comtag = @perspectives.keys[0]
          @comtag = @perspectives[0].tagname
          logger.info("dialogs#slider perspective from first in the list: #{@comtag} for #{@conversation.shortname}")
        end
        if @comtag != '' and current_participant.tag_list_downcase.include?(@comtag.downcase)
          @perspective = @comtag
          session["cur_perspective_#{@conversation.id}"] = @perspective
          logger.info("dialogs#slider settting perspective in cookie: #{@perspective} for #{@conversation.shortname}")
          logger.info("dialogs#slider redirecting to conversation with comtag: #{@perspective}")
          url = "/dialogs/#{@dialog_id}/slider?comtag=#{@comtag}&conv=#{@conversation.shortname}"
          url += "&show_result=1" if @show_result == 1
          redirect_to url
          return
        end
        @perspective = 'outsider'
      else
        # We have a comtag
        logger.info("dialogs#slider perspective from given comtag: #{@comtag} for #{@conversation.shortname}")
        # Is this user a member of any of the communities for the conversation?
        for com in @conversation.communities
          if current_participant.tag_list_downcase.include?(com.tagname.downcase)
            @is_conv_member = true
            # Is it the one selected?
            if com.tagname == @comtag
              # remember it as the current perspective for this conversation
              @perspective = @comtag
              session["cur_perspective_#{@conversation.id}"] = @perspective
              logger.info("dialogs#slider settting perspective in cookie: #{@perspective} for #{@conversation.shortname}")
            end
          end
        end
        @perspective = 'outsider' if @perspective == ''
      end      
      if @comtag == ''
        @perspective = 'outsider'
      end
      if @perspective == 'outsider'
        logger.info("dialogs#slider redirecting to conversation about, because outsider")
        redirect_to "/conversations/#{@conversation.id}"
        return
      end
    end
    
    @geo_levels = [
      [6,'Planet&nbsp;Earth'],
      [5,'My&nbsp;Nation'],
      [4,'State/Province'],
      [3,'My&nbsp;Metro&nbsp;region'],
      [2,'My&nbsp;County'],
      [1,'My&nbsp;City/Town']
    ]
    
    if @nvaction
      @suggestedtopic = "Nonviolent Action for Human Unity"
    elsif true
      @suggestedtopic = "Human Unity and Diversity"
    elsif is_new
      @nvaction = ""
      help_text = HelpText.find_by_code("suggestedtopic")
      if help_text
        @suggestedtopic = help_text.text   
      end
      session[:suggestedtopic] = @suggestedtopic
    else  
      @suggestedtopic = session.has_key?(:suggestedtopic) ? session[:suggestedtopic] : ""
    end
        
    @showing_options = 'less'
    #if @show_result.to_i > 0 and @dialog.default_datetype.to_s != '' and @datetype != @dialog.default_datetype
    #  @showing_options = 'more'
    #end  
    if @show_result.to_i > 0 and @dialog.default_datefixed.to_s != '' and @datefixed != @dialog.default_datefixed
      @showing_options = 'more'
    end  
    #if @show_result.to_i > 0 and @dialog.default_datefrom.to_s != '' and @datefrom != @dialog.default_datefrom
    #  @showing_options = 'more'
    #end  

    #@datefrom = session.has_key?(:datefrom) ? session[:datefrom] : Date.today.beginning_of_month.strftime('%Y-%m-%d')
    logger.info("dialogs#slider datefixed:#{@datefixed}")    
    
    @previous_messages = Item.where("posted_by=? and dialog_id=? and (reply_to is null or reply_to=0)",current_participant.id,@dialog.id).count


    logger.info("dialogs#slider @sortby:#{@sortby} @threads:#{@threads}")
    
    @batch_size = nil
    @batch_level = nil
    if session.include?(:list_batch_size) and session.include?(:slider_dialog_id)
      #-- Look at the previous batch size used and see if we should use the same
      if session[:slider_dialog_id] !=  @dialog.id
        #-- It was for a different discussion
        session.delete(:list_batch_size)
        session.delete(:list_batch_level)
      elsif session.include?(:slider_group_id) and session[:slider_group_id].to_i != @group_id
        #-- It was for a different group
        session.delete(:list_batch_size)
        session.delete(:list_batch_level)
      else
        @batch_size = session[:list_batch_size]
        @batch_level= session[:list_batch_level]
      end
    else
      session.delete(:list_batch_size) if session.include?(:list_batch_size) 
      session.delete(:list_batch_level) if session.include?(:list_batch_level)
    end
    @showmax = @batch_size || 4

  end
  
  def moons
    #-- Show results from X moons ago
    @section = 'dialogs'
    @dsection = 'moons'
    @dialog_id = params[:id].to_i
    @dialog = Dialog.includes(:creator).find(@dialog_id)    
    
    
  end
  
  def show
    redirect_to :action=>:view
  end

  def view
    #-- Presentation for a group one might want to join
    @section = 'dialogs'
    @dsection = 'info'
    @dialog_id = params[:id]
    @dialog = Dialog.includes(:creator).find(@dialog_id)
    @current_period = Period.find(@dialog.current_period) if @dialog.current_period.to_i > 0
    dialogadmin = DialogAdmin.where("dialog_id=? and participant_id=?",@dialog_id, current_participant.id)
    @is_admin = ((dialogadmin.length > 0) or current_participant.sysadmin)
    update_last_url
    update_prefix
  end  

  def admin
    #-- Overview page for administrators and moderators
    @section = 'dialogs'
    @dsection = 'admin'
    @group = Group.find(params[:id])
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).first
    @is_member = @group_participant ? true : false
    @is_moderator = ((@group_participant and @group_participant.moderator) or current_participant.sysadmin)
    update_last_url
    update_prefix
  end

  def new
    #-- Creating a new dialog
    if not current_participant.sysadmin
      redirect_to '/groups'
    end
    @section = 'dialogs'
    @dsection = 'edit'
    @dialog = Dialog.new
    @dialog.created_by = current_participant.id
    @dialog.visibility = 'public'
    @dialog.openness = 'open'
    @dialog.metamap_vote_own = 'never'
    @dialog.multigroup = true 
    @dialog.required_meta = true
    @dialog.required_message = false
    @dialog.value_calc = 'total'
    @dialog.allow_replies = true
    @dialog.profiles_visible = true
    @dialog.names_visible_voting = false
    @dialog.names_visible_general = true
    @dialog.posting_open = true
    @dialog.voting_open = true
    @metamaps = Metamap.where(nil)
    @has_metamaps = {}
    
    @groupsin = GroupParticipant.where("participant_id=#{current_participant.id}").includes(:group)
    render :action=>'edit'
  end  
  
  def edit
    #-- Editing dialog information, only for administrators
    @section = 'dialogs'
    @dsection = 'edit'
    @dialog_id = params[:id]
    dialogadmin = DialogAdmin.where("dialog_id=? and participant_id=?",@dialog_id, current_participant.id)
    if dialogadmin.length == 0 and not current_participant.sysadmin
      redirect_to :action=>:view
    end 
    @is_admin = true
    #@groupsin = GroupParticipant.where("participant_id=#{current_participant.id}").includes(:group)   
    @dialog = Dialog.find_by_id(@dialog_id)
    @metamaps = Metamap.where(nil)
    @has_metamaps = {}
    @dialog.metamaps.each do |metamap_id,name|
      @has_metamaps[metamap_id] = true
    end
    update_prefix
  end  

  def create
    @dialog = Dialog.new(dialog_params)
    respond_to do |format|
      if dvalidate and @dialog.save
        @dialog.participants << current_participant  # Add as admin
        if @dialog.group_id.to_i > 0
          @group = Group.find(@dialog.group_id)
          @dialog.groups << @group
        end
        for metamap in Metamap.where(nil)
          dialog_metamap = DialogMetamap.where(:dialog_id=>@dialog.id,:metamap_id=>metamap.id).first
          if params[:metamap] and params[:metamap][metamap.id.to_s] and not dialog_metamap
            dialog_metamap = DialogMetamap.new(:dialog_id=>@dialog.id,:metamap_id=>metamap.id)
            dialog_metamap.save!
          elsif (not params[:metamap] or not params[:metamap][metamap.id.to_s]) and dialog_metamap
            dialog_metamap.destroy
          end  
        end
        logger.info("dialogs_controller#create New dialog created: #{@dialog.id}")
        flash[:notice] = 'Discussion was successfully created.'
        format.html { redirect_to :action=>:view, :id=>@dialog.id }
      else
        logger.info("dialogs_controller#create Failed creating new discussion")
        format.html { render :action=>:edit }
      end
    end
    update_prefix
  end  
  
  def update
    @dialog_id = params[:id]
    @dialog = Dialog.find(@dialog_id)
    dialogadmin = DialogAdmin.where("dialog_id=? and participant_id=?",@dialog_id, current_participant.id)
    @is_admin = ((dialogadmin.length > 0) or current_participant.sysadmin)
    if not @is_admin
      redirect_to :action=>:view
    end 
    respond_to do |format|
      if dvalidate and @dialog.update_attributes(dialog_params)
        @dialog.shortdesc = view_context.strip_tags(@dialog.shortdesc)[0..123]
        @dialog.save
        for metamap in Metamap.where(nil)
          dialog_metamap = DialogMetamap.where(:dialog_id=>@dialog.id,:metamap_id=>metamap.id).first
          if params[:metamap] and params[:metamap][metamap.id.to_s] and not dialog_metamap
            dialog_metamap = DialogMetamap.new(:dialog_id=>@dialog.id,:metamap_id=>metamap.id)
            dialog_metamap.save!
          elsif (not params[:metamap] or not params[:metamap][metamap.id.to_s]) and dialog_metamap
            dialog_metamap.destroy
          end  
        end
        format.html { redirect_to :action=>:view, :notice => 'Discussion was successfully updated.' }
        format.xml  { head :ok }
      else
        @metamaps = Metamap.where(nil)
        @has_metamaps = {}
        @dialog.metamaps.each do |metamap_id,name|
          @has_metamaps[metamap_id] = true
        end
        format.html { render :action => "edit" }
        format.xml  { render :xml => @dialog.errors, :status => :unprocessable_entity }
      end
    end
  end  

  def forum
    #-- Show most recent items that this user is allowed to see
    #@group_id,@dialog_id = get_group_dialog_from_subdomain
    @section = 'dialogs'
    @dsection = 'forum'
    @from = params[:from] || 'dialog'
    @ratings = params[:ratings]
    if params.has_key?(:simple)
      @simple = (params[:simple].to_i == 1)  # Simplified interface
      if @simple
        current_participant.disc_interface = 'simple'
      else
        current_participant.disc_interface = 'normal'
      end    
      current_participant.save
    else
      @simple = (current_participant.disc_interface == 'simple')
    end
    @xmode = params[:xmode].to_s    # list or single, if in simple mode
    @item_number = params[:item_number].to_i # What item are we looking at, one at a time, in the simplified interface?
    @item_id = params[:item_id].to_i
    @xmode = params[:xmode].to_s
    @exp_item_id = (params[:exp_item_id] || 0).to_i
    @tag = params[:tag].to_s
    @subgroup = params[:subgroup].to_s
    @posted_by_country_code = (params[:posted_by_country_code] || '').to_s
    @posted_by_admin1uniq = (params[:posted_by_admin1uniq] || '').to_s
    @posted_by_metro_area_id = (params[:posted_by_metro_area_id] || 0).to_i
    @rated_by_country_code = (params[:rated_by_country_code] || '').to_s
    @rated_by_admin1uniq = (params[:rated_by_admin1uniq] || '').to_s
    @rated_by_metro_area_id = (params[:rated_by_metro_area_id] || 0).to_i
    session[:group_id] = params[:group_id].to_i if params[:group_id].to_i > 0    
    @dialog_id = params[:id].to_i if not @dialog_id
    @period_id = (params[:period_id] || 0).to_i
    @dialog = Dialog.includes(:groups).find_by_id(@dialog_id)
    @limit_group_id = (params[:limit_group_id] || 0).to_i
    @group = Group.find_by_id(@limit_group_id > 0 ? @limit_group_id : session[:group_id]) if not @group
    @groups = @dialog.groups if @dialog and @dialog.groups
    @periods = @dialog.periods if @dialog and @dialog.periods
    if @period_id > 0
      @period = Period.find_by_id(@period_id)
    elsif @dialog.active_period
      @period = @dialog.active_period
      @period_id = @dialog.active_period.id
    end    
    @limit_group = Group.find_by_id(@limit_group_id) if @limit_group_id > 0
    @has_subgroups = (@limit_group and @limit_group.group_subtags.length > 1)
    if params[:want_crosstalk].to_s != ''
      @want_crosstalk = params[:want_crosstalk].to_s
    else
      @want_crosstalk = session[:want_crosstalk].to_s
    end
    
    if params.has_key?(:show_previous)
      if params[:show_previous].to_i == 1
        @showing_previous = true
      else
        @showing_previous = false
      end
    elsif session.has_key?(:showing_previous)
      @showing_previous = session[:showing_previous]
    elsif @simple
      @showing_previous = false  
    else
      @showing_previous = true  
    end  
    session[:showing_previous] = @showing_previous
    
    if not session[:has_required]
      session[:has_required] = current_participant.has_required
      if not session[:has_required]
        #redirect_to :controller => :profiles, :action=>:edit
        redirect_to '/me/profile/meta'
        return
      end
    #elsif current_participant.new_signup
    #  redirect_to :controller => :profiles, :action=>:edit
    #  return
    end
    
    @metamaps = Metamap.joins(:dialogs).where("dialogs.id=#{@dialog_id}")
    
    @groupsin = GroupParticipant.where("participant_id=#{current_participant.id}").includes(:group)
    dialogadmin = DialogAdmin.where("dialog_id=? and participant_id=?",@dialog_id, current_participant.id)
    @is_admin = (dialogadmin.length > 0 or current_participant.sysadmin)
    
    @previous_messages = Item.where("posted_by=? and dialog_id=? and (reply_to is null or reply_to=0)",current_participant.id,@dialog.id).count
    if @dialog.current_period.to_i > 0
      @previous_messages_period = Item.where("posted_by=? and dialog_id=? and period_id=? and (reply_to is null or reply_to=0)",current_participant.id,@dialog.id,@dialog.current_period.to_i).count      
    end
    
    if participant_signed_in? and current_participant.forum_settings
      set = current_participant.forum_settings
    else
      set = {}
    end    
    #@sortby = params[:sortby] || set['sortby'] || "default"
    @sortby = params[:sortby] || "default"
    @perscr = (params[:perscr] || set['perscr'] || 25).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    @threads = params[:threads] || set['threads'] || 'flat'
    #@threads = params[:threads] || set['threads'] || 'flat'
    #@threads = 'flat' if @threads == ''
    #@threads = 'flat'

    @show_meta = false
    
    #get_params = Rack::Utils.parse_query request.fullpath
    
    if @dialog.active_period and not @from=='result' and not (params[:perscr].to_i==100 and params[:threads]=='flat' and not params.include?(:page))
      @sortby = 'default'
    end
      
    if @sortby == 'default' and not @dialog.active_period
      #-- Default sort set, but there isn't any active period
      @sortby = 'items.id desc'
      sortby = @sortby
      @threads = 'flat'
    elsif @sortby == 'default'
      sortby = 'items.id desc'
      #@items = @items.where("metamap_nodes.metamap_id=4")
      @threads = 'root'
    elsif @sortby[0,5] == 'meta:'
      metamap_id = @sortby[5,10].to_i
      sortby = "metamap_nodes.name"
      @items = @items.where("metamap_nodes.metamap_id=#{metamap_id}")
      @show_meta = false
    else
      sortby = @sortby
    end
    
    if @threads == 'flat' or @threads == 'tree' or @threads == 'root'
      @rootonly = true
    end
    
    @posted_meta={}
    @rated_meta={}
    params.each do |var,val|
      if var[0,18] == 'posted_by_metamap_'
        metamap_id = var[18,].to_i
        if params["posted_by_metamap_#{metamap_id}"].to_i > 0
          @posted_meta[metamap_id] = params["posted_by_metamap_#{metamap_id}"].to_i
        end
      elsif var[0,17] == 'rated_by_metamap_'
        metamap_id = var[17,].to_i
        if params["rated_by_metamap_#{metamap_id}"].to_i > 0
          @rated_meta[metamap_id] = params["rated_by_metamap_#{metamap_id}"].to_i
        end
      end
    end

    if @simple
      #-- If simple mode, count how many items haven't yet been rated by this user
      @num_unrated = Item.where(dialog_id: @dialog_id, period_id: @period_id, is_first_in_thread: true).joins("left outer join ratings on (ratings.item_id=items.id and ratings.participant_id=#{current_participant.id})").where("ratings.id is null").count
    end

    #-- Get the records, while adding up the stats on the fly

    #@items, @itemsproc, @extras = Item.list_and_results(@limit_group,@dialog,@period_id,0,@posted_meta,@rated_meta,@rootonly,@sortby,current_participant)

    #if @simple and not @xmode=='list' and not @xmode=='single'
    #  #-- Showing messages without ratings if we're in simple mode and not in list mode or single mode
    #  withratings = 'no'
    #else
      withratings = ''
    #end

    @items, @itemsproc, @extras = Item.list_and_results(@limit_group,@dialog,@period_id,0,@posted_meta,@rated_meta,@rootonly,@sortby,current_participant,true,0,'','',@posted_by_country_code,@posted_by_admin1uniq,@posted_by_metro_area_id,@rated_by_country_code,@rated_by_admin1uniq,@rated_by_metro_area_id,@tag,@subgroup,false,withratings,'',@want_crosstalk)

    #if @simple and not @xmode=='list' and not @xmode=='single' and @items.length == 0
    #  #-- If we're in simple mode and not specifically single mode, and there aren't any unrated message, show the full list
    #  @xmode = 'list'
    #  withratings = ''
    #  @items, @itemsproc, @extras = Item.list_and_results(@limit_group,@dialog,@period_id,0,@posted_meta,@rated_meta,@rootonly,@sortby,current_participant,true,0,'','',@posted_by_country_code,@posted_by_admin1uniq,@posted_by_metro_area_id,@rated_by_country_code,@rated_by_admin1uniq,@rated_by_metro_area_id,@tag,@subgroup,false,withratings)
    #end
    if @simple and not @xmode=='list' and not @xmode=='single' and @num_unrated == 0
      @xmode = 'list'
    end   

    #@items, @itemsproc, @extras = Item.list_and_results(@limit_group,@dialog,@period_id,@posted_by,@posted_meta,@rated_meta,@rootonly,@sortby,current_participant,true,0,'','',@posted_by_country_code,@posted_by_admin1uniq,@posted_by_metro_area_id,@rated_by_country_code,@rated_by_admin1uniq,@rated_by_metro_area_id,@tag,@subgroup)
    
    #if @sortby == 'default'
    #  @items = Item.custom_item_sort(@items, @page, @perscr, current_participant.id, @dialog).paginate :page=>@page, :per_page => @perscr
    #else
    #  @items = @items.order(sortby)
    #end
    
    if current_participant.new_signup
      @new_signup = true
      current_participant.new_signup = false
      current_participant.save
    #elsif session[:new_signup].to_i == 1
    #  @new_signup = true
    #  session[:new_signup] = 0
    elsif params[:new_signup].to_i == 1
      @new_signup = true
    end
    
    update_last_url
    update_prefix
    
    if @simple and @dialog.active_period
      #-- Simplified interface, only if we have an active decision period
      if @item_number == 0 and @item_id == 0 and @xmode != 'list'
        @item_number = 1
      end  
      if @item_number > 0 or @item_id > 0
        if @item_id.to_i > 0
          @item_number = 1
          for item in @items
            if item.id == @item_id
              @item = item
              break
            end  
            @item_number += 1
          end  
          #@item = Item.find_by_id(@item_id)
        elsif @item_number.to_i > 1 and @item_number < @items.length
          @item = @items[@item_number-1]
        else
          @item_number = 1
          @item = @items[0]
        end  
        #-- If @item_number is set, we'll show items one by one. Otherwise a listing
        if @item_number > 1
          @prev_item_id = @items[@item_number-2].id
        else
          @prev_item_id = 0
        end    
        if @item_number < @items.length
          @next_item_id = @items[@item_number].id
        else
          @next_item_id = 0
        end    
      end  
      render :action => :forum_dsimple, :layout => 'front_nomenu'
    else
      @items = @items.paginate :page=>@page, :per_page => @perscr  
      render :action => :forum  
    end

  end   
  
  def show_latest
    #-- Get any new postings into the simple list mode for a certain discussion/period by ajax
    @dialog_id = params[:id].to_i
    @period_id = params[:period_id].to_i
    
    @last_item_id = params[:last_item_id].to_i
    @odd_or_even = params[:odd_or_even]
    
    @new_items = Item.where(dialog_id: @dialog_id, period_id: @period_id).where("id>#{@last_item_id}").count
    
    if @new_items > 0
      @sortby == 'default'
      sortby = 'items.id desc'
      @threads = 'root'
      @rootonly = true
      withratings = ''
      @limit_group = 0
      @posted_meta={}
      @rated_meta={}
      @posted_by_country_code = ''
      @posted_by_admin1uniq = ''
      @posted_by_metro_area_id = 0
      @rated_by_country_code = ''
      @rated_by_admin1uniq = ''
      @rated_by_metro_area_id = 0
      @tag = ''
      @subgroup = ''

      @items, @itemsproc, @extras = Item.list_and_results(@limit_group,@dialog_id,@period_id,0,@posted_meta,@rated_meta,@rootonly,@sortby,current_participant,true,0,'','',@posted_by_country_code,@posted_by_admin1uniq,@posted_by_metro_area_id,@rated_by_country_code,@rated_by_admin1uniq,@rated_by_metro_area_id,@tag,@subgroup,false,withratings)
    
      @items.delete_if{|item| item.id <= @last_item_id}
      
      @items.each{|item| @last_item_id = item.id if item.id > @last_item_id}
    
      render :partial => 'items/list_dsimple'
    
    else
    
      render plain: ''
    
    end
    
  end
  
  def period_edit
    @dialog_id = params[:id].to_i
    @dialog = Dialog.find(@dialog_id)
    dialogadmin = DialogAdmin.where("dialog_id=? and participant_id=?",@dialog_id, current_participant.id)
    if dialogadmin.length == 0 and not current_participant.sysadmin
      redirect_to :action=>:view
    end 
    @is_admin = true       
    @period_id = params[:period_id].to_i
    if @period_id == 0
      @period = Period.new(:dialog_id=>@dialog_id,:group_dialog=>'dialog')
      @period.metamap_vote_own = 'never'
      @period.required_meta = true
      @period.required_message = false
      @period.value_calc = 'total'
      @period.allow_replies = true
      @period.profiles_visible = true
      @period.names_visible_voting = false
      @period.names_visible_general = true
      @period.posting_open = true
      @period.voting_open = true
    else
      @period = Period.find(@period_id)
    end
    @metamaps = Metamap.order("name")  
  end
  
  def period_save
    @dialog_id = params[:id].to_i
    @dialog = Dialog.find(@dialog_id)
    @period_id = params[:period_id].to_i    
    if @period_id > 0
      @period = Period.find(@period_id)
    else
      @period = Period.new()
      @period.dialog_id = @dialog_id
      @period.group_dialog = 'dialog'
    end  
    @period.shortdesc = view_context.strip_tags(@period.shortdesc.to_s)[0..123]
    #@period.shortdesc = ActionController::Base.helpers.strip_tags(@period.shortdesc.to_s)[0..123]
    @period.save!    
    @period.update_attributes(period_params)
    #@period.required_meta = params[:period][:required_meta]
		#@period.required_message = params[:period][:required_message]
		#@period.required_subject = params[:period][:required_subject]
		#@period.allow_replies = params[:period][:allow_replies]
		#@period.profiles_visible = params[:period][:profiles_visible]
		#@period.names_visible_voting = params[:period][:names_visible_voting]
		#@period.names_visible_general = params[:period][:names_visible_general]
		#@period.in_voting_round = params[:period][:in_voting_round]
		#@period.posting_open = params[:period][:posting_open]
		#@period.voting_open = params[:period][:voting_open]
		#@period.save!
    redirect_to :action=>:edit
  end
  
  def group_settings
    #-- Show/edit the specifics for the group dialog membership
    @dialog_id = params[:id].to_i
    @dialog = Dialog.find_by_id(@dialog_id)
    @group_id = params[:group_id].to_i
    @group = Group.find(@group_id)
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).first
    @is_member = @group_participant ? true : false
    @is_moderator = ((@group_participant and @group_participant.moderator) or current_participant.sysadmin)
    @dialog_group = DialogGroup.where("group_id=#{@group_id} and dialog_id=#{@dialog_id}").first   
  end
  
  def group_settings_save
    @dialog_group_id = params[:dialog_group_id]
    @dialog_group = DialogGroup.find_by_id(@dialog_group_id)
    @dialog_group.active = params[:dialog_group][:active]
    @dialog_group.apply_status = params[:dialog_group][:apply_status]
    @dialog_group.processed_by = current_participant.id
    @dialog_group.save!
    redirect_to :action=>:edit
  end
  
  def meta
    #-- Show some stats, according to the metamaps
    @section = 'dialogs'
    @dsection = 'meta'
    @from = 'dialog'
    @dialog_id = params[:id].to_i
    @dialog = Dialog.includes(:periods).find_by_id(@dialog_id)
    dialogadmin = DialogAdmin.where("dialog_id=? and participant_id=?",@dialog_id, current_participant.id)
    @is_admin = (dialogadmin.length > 0 or current_participant.sysadmin)
    @period_id = params[:period_id].to_i
    
    @metamaps = Metamap.joins(:dialogs).where("dialogs.id=#{@dialog_id}")

    #r = Participant.joins(:groups=>:dialogs).joins(:metamap_nodes).where("dialogs.id=3").where("metamap_nodes.metamap_id=2").select("participants.id,first_name,metamap_nodes.name as metamap_node_name")

    #-- Find how many people and items for each metamap_node
    @data = {}
    for metamap in @metamaps

      metamap_id = metamap.id

      @data[metamap.id] = {}
      @data[metamap.id]['name'] = metamap.name
      @data[metamap.id]['nodes'] = {}  # All nodes that have been used, for posting or rating
      @data[metamap.id]['postedby'] = { # stats for what was posted by people in those meta categories
        'nodes' => {}
      }    
      @data[metamap.id]['ratedby'] = {     # stats for what was rated by people in those meta categories
        'nodes' => {}      
      }
      @data[metamap.id]['matrix'] = {      # stats for posted by meta cats crossed by rated by metacats
        'post_rate' => {},
        'rate_post' => {}
      }
      @data[metamap.id]['items'] = {}     # To keep track of the meta cat for each item
      @data[metamap.id]['ratings'] = {}     # To keep track of the meta cat for each rating

      pwhere = (@period_id > 0) ? "items.period_id=#{@period_id}" : ""

      #-- Everything posted, with metanode info
      items = Item.where("items.dialog_id=#{@dialog_id}").where(pwhere).includes(:participant=>{:metamap_node_participants=>:metamap_node}).includes(:item_rating_summary).where("metamap_node_participants.metamap_id=#{metamap_id}")
      
      #-- Everything rated, with metanode info
      ratings = Rating.where("ratings.dialog_id=#{@dialog_id}").where(pwhere).includes(:participant=>{:metamap_node_participants=>:metamap_node}).includes(:item=>:item_rating_summary).where("metamap_node_participants.metamap_id=#{metamap_id}")
      
      #-- Going through everything posted, group by meta node
      for item in items
        item_id = item.id
        poster_id = item.posted_by
        metamap_node_id = item.participant.metamap_node_participants[0].metamap_node_id
        metamap_node_name = item.participant.metamap_node_participants[0].metamap_node.name
        @data[metamap.id]['items'][item.id] = metamap_node_id
        if not @data[metamap.id]['nodes'][metamap_node_id]
          @data[metamap.id]['nodes'][metamap_node_id] = metamap_node_name
        end
        if not @data[metamap.id]['postedby']['nodes'][metamap_node_id]
          @data[metamap.id]['postedby']['nodes'][metamap_node_id] = {
            'name' => item.participant.metamap_node_participants[0].metamap_node.name,
            'items' => {},
            'itemsproc' => {},
            'posters' => {},
            'ratings' => {}
          }
        end
        if not @data[metamap.id]['matrix']['post_rate'][metamap_node_id]
          @data[metamap.id]['matrix']['post_rate'][metamap_node_id] = {}
        end
        @data[metamap.id]['postedby']['nodes'][metamap_node_id]['items'][item_id] = item
        @data[metamap.id]['postedby']['nodes'][metamap_node_id]['posters'][poster_id] = item.participant
      end

      #-- Going through everything rated, group by meta node
      for rating in ratings
        rating_id = rating.id
        item_id = rating.item_id
        rater_id = rating.participant_id
        metamap_node_id = rating.participant.metamap_node_participants[0].metamap_node_id
        metamap_node_name = rating.participant.metamap_node_participants[0].metamap_node.name
        if not @data[metamap.id]['nodes'][metamap_node_id]
          @data[metamap.id]['nodes'][metamap_node_id] = metamap_node_name
        end
        @data[metamap.id]['ratings'][rating.id] = metamap_node_id
        if not @data[metamap.id]['ratedby']['nodes'][metamap_node_id]
          @data[metamap.id]['ratedby']['nodes'][metamap_node_id] = {
            'name' => rating.participant.metamap_node_participants[0].metamap_node.name,
            'items' => {},
            'itemsproc' => {},
            'raters' => {},
            'ratings' => {}
          }
        end
        if not @data[metamap.id]['matrix']['rate_post'][metamap_node_id]
          @data[metamap.id]['matrix']['rate_post'][metamap_node_id] = {}
        end
        @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['items'][item_id] = rating.item
        @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['raters'][rater_id] = rating.participant
        @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['ratings'][rating_id] = rating
        item_metamap_node_id = @data[metamap.id]['items'][item_id]
        @data[metamap.id]['postedby']['nodes'][item_metamap_node_id]['ratings'][rating_id] = rating
        if not @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id]
          @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id] = {
            'post_name' => '',
            'rate_name' => '',
            'items' => {},
            'itemsproc' => {},
            'ratings' => {}
          }
        end
        @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id]['ratings'][rating_id] = rating
        @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id]['items'][item_id] = rating.item
        @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id]['post_name'] = @data[metamap.id]['nodes'][item_metamap_node_id]
        @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id]['rate_name'] = metamap_node_name
      end  # ratings

      #-- Adding up stats for postedby items
      @data[metamap.id]['postedby']['nodes'].each do |metamap_node_id,mdata|
        # {'num_items'=>0,'num_ratings'=>0,'avg_rating'=>0.0,'num_interest'=>0,'num_approval'=>0,'avg_appoval'=>0.0,'avg_interest'=>0.0,'avg_value'=>0,'value_winner'=>0}
        mdata['items'].each do |item_id,item|
          iproc = {'id'=>item.id,'name'=>item.participant.name,'subject'=>item.subject,'num_interest'=>0,'tot_interest'=>0,'avg_interest'=>0.0,'num_approval'=>0,'tot_approval'=>0,'avg_approval'=>0.0,'value'=>0.0}
          mdata['ratings'].each do |rating_id,rating|
            if rating.item_id == item.id
              if rating.interest.to_i > 0
                iproc['num_interest'] += 1
                iproc['tot_interest'] += rating.interest
                iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
              end
              if rating.approval.to_i > 0
                iproc['num_approval'] += 1
                iproc['tot_approval'] += rating.approval
                iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
              end
              iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
            end
          end
          @data[metamap.id]['postedby']['nodes'][metamap_node_id]['itemsproc'][item_id] = iproc
        end
        @data[metamap.id]['postedby']['nodes'][metamap_node_id]['itemsproc'] = @data[metamap.id]['postedby']['nodes'][metamap_node_id]['itemsproc'].sort {|a,b| b[1]['value']<=>a[1]['value']}
      end
      
      #-- Adding up stats for ratedby items
      @data[metamap.id]['ratedby']['nodes'].each do |metamap_node_id,mdata|
        # {'num_items'=>0,'num_ratings'=>0,'avg_rating'=>0.0,'num_interest'=>0,'num_approval'=>0,'avg_appoval'=>0.0,'avg_interest'=>0.0,'avg_value'=>0,'value_winner'=>0}
        mdata['items'].each do |item_id,item|
          iproc = {'id'=>item.id,'name'=>item.participant.name,'subject'=>item.subject,'num_interest'=>0,'tot_interest'=>0,'avg_interest'=>0.0,'num_approval'=>0,'tot_approval'=>0,'avg_approval'=>0.0,'value'=>0.0}
          mdata['ratings'].each do |rating_id,rating|
            if rating.item_id == item.id
              if rating.interest.to_i > 0
                iproc['num_interest'] += 1
                iproc['tot_interest'] += rating.interest
                iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
              end
              if rating.approval.to_i > 0
                iproc['num_approval'] += 1
                iproc['tot_approval'] += rating.approval
                iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
              end
              iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
            end
          end
          @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['itemsproc'][item_id] = iproc
        end
        @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['itemsproc'] = @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['itemsproc'].sort {|a,b| b[1]['value']<=>a[1]['value']}
      end
      
      #-- Adding up matrix stats
      @data[metamap.id]['matrix']['post_rate'].each do |item_metamap_node_id,rdata|
        rdata.each do |rate_metamap_node_id,mdata|

          mdata['items'].each do |item_id,item|
            iproc = {'id'=>item.id,'name'=>item.participant.name,'subject'=>item.subject,'num_interest'=>0,'tot_interest'=>0,'avg_interest'=>0.0,'num_approval'=>0,'tot_approval'=>0,'avg_approval'=>0.0,'value'=>0.0}
            mdata['ratings'].each do |rating_id,rating|
              if rating.item_id == item.id
                if rating.interest.to_i > 0
                  iproc['num_interest'] += 1
                  iproc['tot_interest'] += rating.interest
                  iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
                end
                if rating.approval.to_i > 0
                  iproc['num_approval'] += 1
                  iproc['tot_approval'] += rating.approval
                  iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
                end
                iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
              end
            end
            @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['itemsproc'][item_id] = iproc
          end
          @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['itemsproc'] = @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['itemsproc'].sort {|a,b| b[1]['value']<=>a[1]['value']}

        end
      end

    end # metamaps

    update_last_url
    update_prefix

  end

  def result
    #-- Results for a particular dialog/period, now based on list_and_results in the item class
    #-- Results will typically show the overall result, followed by the different meta category results, followed by by group
    #-- Gender/Age Crosstalk is simplified, though

    @section = 'dialogs'
    @dsection = 'meta'
    
    @from = 'dialog'
    @dialog_id = params[:id].to_i
    @dialog = Dialog.includes(:periods).find_by_id(@dialog_id)
    dialogadmin = DialogAdmin.where("dialog_id=? and participant_id=?",@dialog_id, current_participant.id)
    @is_admin = (dialogadmin.length > 0 or current_participant.sysadmin)
    @less_more = params[:less_more] || 'less'

    @period_id = params[:period_id].to_i

    if not params.include?(:period_id) 
      if @dialog.current_period.to_i > 0
        #-- Use the current period, if we aren't being told anything else
        @period_id = @dialog.current_period.to_i
      else
        #-- If there's no current period, use the most recent one, if there is one
        @period = @dialog.recent_period
        @period_id = @period.id if @period
      end
    end
    @period = Period.find_by_id(@period_id) if not @period

    if params[:short_full].to_s != ''
      @short_full = params[:short_full]
      if not @period and (@short_full == 'gender' or @short_full == 'age')
        #-- If gender/age is no longer set (period changed), make sure they aren't selected
        @short_full = 'short'
      elsif (@period and params[:period_id_bef].to_i > 0 and @period.id != params[:period_id_bef].to_i)
        #-- If period was changed, move back to default short_full
        @short_full = ''
      end  
    end  
      
    if @short_full.to_s != ''
    elsif @period and (@period.crosstalk == 'gender' or @period.crosstalk == 'gender1')
      @short_full = 'gender'
    elsif @period and (@period.crosstalk == 'age' or @period.crosstalk == 'age1')
      @short_full = 'age'
    else
      @short_full = 'short'
    end

    if @short_full == 'short' or @short_full == 'gender' or @short_full == 'age'
      @limit_group_id = 0
      @regress = 'regress'
    else  
      @limit_group_id = (params[:limit_group_id] || 0).to_i
      @limit_group = @limit_group_id > 0 ? Group.find_by_id(@limit_group_id) : nil
      @regress = params[:regress] || 'regress'
    end

    @sortby = '*value*'

    @regmean = (@regress == 'regress')
    @all = (@short_full == 'full')
    
    @data = {}
    
    #-- Lets start with the overall results
    #list_and_results(group=nil,dialog=nil,period_id=0,posted_by=0,posted_meta={},rated_meta={},rootonly=true,sortby='',participant=nil,regmean=true,visible_by=0,start_at='',end_at='',posted_by_country_code='',posted_by_admin1uniq='',posted_by_metro_area_id=0,rated_by_country_code='',rated_by_admin1uniq='',rated_by_metro_area_id=0,tag='',subgroup='')
    items, itemsproc, extras = Item.list_and_results(@limit_group,@dialog,@period_id,0,{},{},true,@sortby,current_participant,@regmean,0,'','','','','','','','','','',true)
    @data['totals'] = {'items'=>items, 'itemsproc'=>itemsproc, 'extras'=>extras}
    @data['meta'] = extras['meta']    

#    items = Item.where("items.dialog_id=#{@dialog_id}").where(pwhere).where(gwhere).where("is_first_in_thread=1").includes(:participant).includes(:item_rating_summary)

    #-- Then by group, if there is more than one, and none has been selected
    @data['groups'] = {}
    if @limit_group_id == 0
      #-- Stats by group
      for group in @dialog.groups
        #list_and_results(group=nil,dialog=nil,period_id=0,posted_by=0,posted_meta={},rated_meta={},rootonly=true,sortby='',participant=nil,regmean=true,visible_by=0,start_at='',end_at='',posted_by_country_code='',posted_by_admin1uniq='',posted_by_metro_area_id=0,rated_by_country_code='',rated_by_admin1uniq='',rated_by_metro_area_id=0,tag='',subgroup='')
        items, itemsproc, extras = Item.list_and_results(group,@dialog,@period_id,0,@posted_meta,@rated_meta,@rootonly,@sortby,current_participant,true,0,'','','','','','','','','','')        
        @data['groups'][group.id] = {'items'=>items, 'itemsproc'=>itemsproc, 'extras'=>extras}
      end
    end
    
    #-- Then stats by metamap
    #-- We need winner posted by the meta category, rated by itself
    #-- We also need what the mata cat chooses as winner out of all, and what all chooses posted by that meta cat
    #-- And anything rated by anything
    #items, itemsproc, extras = Item.list_and_results(@limit_group,@dialog,@period_id,0,{},{},true,@sortby,current_participant,true,0,'','','','','','','','','','')
    @metamaps = Metamap.where(:id=>[3,5])
    
    #-- Check cross results and see if the voice of humanity matches one of them
    @cross_results = cross_results
    #list_and_results(group=nil,dialog=nil,period_id=0,posted_by=0,posted_meta={},rated_meta={},rootonly=true,sortby='',participant=nil,regmean=true,visible_by=0,start_at='',end_at='',posted_by_country_code='',posted_by_admin1uniq='',posted_by_metro_area_id=0,rated_by_country_code='',rated_by_admin1uniq='',rated_by_metro_area_id=0,tag='',subgroup='')
    #list_and_results(group=nil,dialog=nil,period_id=0,posted_by=0,posted_meta={},rated_meta={},rootonly=true,sortby='',participant=nil,regmean=true,visible_by=0,start_at='',end_at='',posted_by_country_code='',posted_by_admin1uniq='',posted_by_metro_area_id=0,rated_by_country_code='',rated_by_admin1uniq='',rated_by_metro_area_id=0,tag='',subgroup='')
    #list_and_results(group=nil,dialog=nil,period_id=0,posted_by=0,posted_meta={},rated_meta={},rootonly=true,sortby='',participant=nil,regmean=true,visible_by=0,start_at='',end_at='',posted_by_country_code='',posted_by_admin1uniq='',posted_by_metro_area_id=0,rated_by_country_code='',rated_by_admin1uniq='',rated_by_metro_area_id=0,tag='',subgroup='')
    
    
  end  

  def previous_result
    #-- Show a snippet that can appear at the top of the forum, indicating the results for the previous round
    #-- http://intermix.dev:3002/dialogs/4/previous_result?period_id=3&crosstalk=gender
    #-- This is most likely called from the script that caches it
    @dialog_id = params[:id].to_i
    @dialog = Dialog.includes(:periods).find_by_id(@dialog_id)
    @period_id = params[:period_id].to_i    # This is the period we want results for
    @period = Period.find_by_id(@period_id)
    @crosstalk = params[:crosstalk]
    
    #puts "  previous_result: crosstalk #{@crosstalk} for period #{@period_id} of discussion #{@dialog_id}"
    logger.info("dialogs#previous_result crosstalk #{@crosstalk} for period #{@period_id} of discussion #{@dialog_id}")
    
    if @crosstalk == 'gender'
      @metamaps = Metamap.where(:id=>[3])
    elsif @crosstalk == 'age'
      @metamaps = Metamap.where(:id=>[5])
    else
      @metamaps = Metamap.where(:id=>[3,5])
    end
    
    @data = {}
    @result = []
  
    #-- Overall results
    items, itemsproc, extras = Item.list_and_results(nil,@dialog,@period.id,0,{},{},true,'*value*',nil,true,0,'','','','','','','','','','',true)
    @data['totals'] = {'items'=>items, 'itemsproc'=>itemsproc, 'extras'=>extras}
    @data['meta'] = extras['meta']    

    #-- Check cross results and see if the voice of humanity matches one of them
    @cross_results = cross_results

    #-- Meta category results
    @data['meta'] = extras['meta'] 
    #if @period.crosstalk[0..5] == 'gender' or @period.crosstalk[0..2] == 'age'
    if true
      for metamap in @metamaps
        #if @period.crosstalk[0..5] == 'gender' and metamap.id == 3
        #elsif @period.crosstalk[0..2] == 'age' and metamap.id == 5
        #else
        #  next
        #end
        #next if @cross_results[metamap.id]['aggsum']
        puts "  meta:##{metamap.id}:#{metamap.name}"
        logger.info("dialogs#previous_result meta:##{metamap.id}:#{metamap.name}")
        @metamap_id = metamap.id
    
        #puts @data['meta'][metamap.id]['nodes_sorted'].inspect
        for metamap_node_id,minfo in @data['meta'][metamap.id]['nodes_sorted']
      		metamap_node_name = minfo[0]
      		metamap_node = minfo[1]
      		if  @data['meta'][metamap.id]['postedby']['nodes'][metamap_node_id] and  @data['meta'][metamap.id]['postedby']['nodes'][metamap_node_id]['items'].length > 0
      			if @data['meta'][metamap.id]['matrix']['post_rate'][metamap_node_id].length > 0
        			for rate_metamap_node_id,rdata in @data['meta'][metamap.id]['matrix']['post_rate'][metamap_node_id]
        			  if rate_metamap_node_id == metamap_node_id
                  
                  if metamap_node_id == @cross_results[metamap.id]['sumcat']
                    #-- This is the summary category, use totals, rather than category results
                    
                    item = @data['totals']['items'][0]
                    item_id = item.id
                    # @itemsproc = @data['totals']['itemsproc']
                    i = @data['totals']['itemsproc'][item_id]
                    is_sumcat = true
                    
                  else
                  
      	            item_id,i = @data['meta'][metamap.id]['matrix']['post_rate'][metamap_node_id][rate_metamap_node_id]['itemsproc'][0]
        	          item = Item.find_by_id(item_id)
                    is_sumcat = false
                  
                  end
                  
      	          puts "    #{metamap_node_name}: #{item.participant.name}: #{item.subject}"
                  logger.info("dialogs#previous_result #{metamap_node_name}: #{item.participant.name}: #{item.subject}")
      	          #result[period.crosstalk] << {'item'=>item,'iproc'=>itemsproc[item.id],'label'=>metamap_node_name}
                
                  useitem = item.attributes
                
                  useitem['subgroup_list'] = item.subgroup_list
                  useitem['show_subgroup'] = item.show_subgroup
                  useitem['tag_list'] = item.tag_list_downcase
                  useitem['item_rating_summary'] = item.item_rating_summary
                
                  useitem['participant'] = item.participant ? item.participant.attributes : nil
                  useitem['dialog'] = item.dialog ? item.dialog.attributes : nil
                  useitem['group'] = item.group ? item.group.attributes : nil
                  useitem['period'] = item.period ? item.period.attributes : nil
                
                  useitem['participant']['name'] = item.participant.name if item.participant
                  useitem['dialog']['settings_with_period'] = item.dialog.settings_with_period if item.dialog

                  #iproc = itemsproc[item.id]
                  iproc = i
                  # What was the intention of this
                  #useiproc = []
                 
                  crosstalkresult = {'item'=>useitem,'iproc'=>iproc,'label'=>metamap_node_name,'metamap_id'=>metamap.id,'metamap_node_id'=>metamap_node_id,'hide'=>false,'combinesum'=>false}
                
                  sumcat = @cross_results[metamap.id]['sumcat']
                  if is_sumcat and @cross_results[metamap.id]['aggsum']
                    crosstalkresult['hide'] = true
                  elsif metamap_node_id != sumcat and item_id == @cross_results[metamap.id]['nodes'][sumcat]
                    crosstalkresult['combinesum'] = true
                    crosstalkresult['label'] =  metamap_node_name + " + Voice of Humanity"
                  end
                
                  @result << crosstalkresult                
                
      	        end
      	      end
      	    end
          end
        end  
        logger.info("dialogs#previous_result meta:##{metamap.id}:#{metamap.name} got #{@result.length} result items")
    
      end   
    end
    
    # @crosstalk and @is_previous_result should change the ways Ids show, to not duplicate existing DOM elements
    @is_previous_result = true
    
    render :partial => 'previous_result'
  end
  
  def cross_results
    #-- Called by result and previous_result    
    #-- Check cross results and see if the voice of humanity matches one of them
    #-- Needs @data to already have been filled in and @metamaps to be available
    @cross_results = {}
    for metamap in @metamaps
      next if not [3,5].include?(metamap.id)
      @cross_results[metamap.id] = {'sumcat'=>0,'aggsum'=>false,'nodes'=>{}}
    	for metamap_node_id,minfo in @data['meta'][metamap.id]['nodes_sorted']
    		metamap_node_name = minfo[0]
    		metamap_node = minfo[1]
        @cross_results[metamap.id][metamap_node_id] = {}
        if metamap_node.sumcat
          #-- This is the voice of humanity summary category
          sumcat = metamap_node.id
          @cross_results[metamap.id]['sumcat'] = metamap_node.id
          gotdata = false
          if @data['totals']['items'].length > 0
            item = @data['totals']['items'][0]
            item_id = item.id
            i = @data['totals']['itemsproc'][item_id]
            gotdata = true
            @cross_results[metamap.id]['nodes'][metamap_node_id] = item_id
          end
        else
          #-- This is not the summary category
          gotdata = false
          if @data['meta'][metamap.id]['matrix']['post_rate'][metamap_node_id]
            for rate_metamap_node_id,rdata in @data['meta'][metamap.id]['matrix']['post_rate'][metamap_node_id]
              if rate_metamap_node_id == metamap_node_id
                if @data['meta'][metamap.id]['matrix']['post_rate'][metamap_node_id][rate_metamap_node_id]['itemsproc'].length > 0
    				      item_id,i = @data['meta'][metamap.id]['matrix']['post_rate'][metamap_node_id][rate_metamap_node_id]['itemsproc'].first
    				      item = Item.find_by_id(item_id)
                  gotdata = true
                  @cross_results[metamap.id]['nodes'][metamap_node_id] = item_id
                end
              end
            end
          end
        end
        if @cross_results[metamap.id]['sumcat'] == 0
          #-- Didn't find the summary category. Look again
          xmetamap_node = MetamapNode.where(metamap_id: metamap.id, sumcat: true).first
          if xmetamap_node
            @cross_results[metamap.id]['sumcat'] = xmetamap_node.id
          end
        end
      end
      @cross_results[metamap.id]['nodes'].each do |metamap_node_id,item_id|
        if metamap_node_id != sumcat and item_id == @cross_results[metamap.id]['nodes'][sumcat]
          #-- Flag that there is a category has the same result as the summary category.
          @cross_results[metamap.id]['aggsum'] = true
        end
      end
    end
    return @cross_results
  end

  def result_old
    #-- Results for a particular dialog/period
    #@section = 'results'    
    @section = 'dialogs'
    @dsection = 'meta'
    
    @from = 'dialog'
    @dialog_id = params[:id].to_i
    @dialog = Dialog.includes(:periods).find_by_id(@dialog_id)
    dialogadmin = DialogAdmin.where("dialog_id=? and participant_id=?",@dialog_id, current_participant.id)
    @is_admin = (dialogadmin.length > 0 or current_participant.sysadmin)
    @less_more = params[:less_more] || 'less'

    @period_id = params[:period_id].to_i

    if not params.include?(:period_id) 
      if @dialog.current_period.to_i > 0
        #-- Use the current period, if we aren't being told anything else
        @period_id = @dialog.current_period.to_i
      else
        #-- If there's no current period, use the most recent one, if there is one
        @period = @dialog.recent_period
        @period_id = @period.id if @period
      end
    end
    @period = Period.find_by_id(@period_id) if not @period

    if params[:short_full].to_s != ''
      @short_full = params[:short_full]
      if not @period and (@short_full == 'gender' or @short_full == 'age')
        #-- If gender/age is no longer set (period changed), make sure they aren't selected
        @short_full = 'short'
      elsif (@period and params[:period_id_bef].to_i > 0 and @period.id != params[:period_id_bef].to_i)
        #-- If period was changed, move back to default short_full
        @short_full = ''
      end  
    end  
      
    if @short_full.to_s != ''
    elsif @period and (@period.crosstalk == 'gender' or @period.crosstalk == 'gender1')
      @short_full = 'gender'
    elsif @period and (@period.crosstalk == 'age' or @period.crosstalk == 'age1')
      @short_full = 'age'
    else
      @short_full = 'short'
    end

    if @short_full == 'short' or @short_full == 'gender' or @short_full == 'age'
      @limit_group_id = 0
      @regress = 'regress'
    else  
      @limit_group_id = (params[:limit_group_id] || 0).to_i
      @limit_group = @limit_group_id > 0 ? Group.find_by_id(@limit_group_id) : nil
      @regress = params[:regress] || 'regress'
    end
    
    
    #@regmean = ((params[:regmean] || 1).to_i == 1)
    @regmean = (@regress == 'regress')
    #@all = (params[:all].to_i == 1)
    @all = (@short_full == 'full')

    #-- Criterion, if we're limiting by period
    pwhere = (@period_id > 0) ? "items.period_id=#{@period_id}" : ""

    #-- or by group
    gwhere = (@limit_group_id > 0) ? "items.group_id=#{@limit_group_id}" : ""

    @data = {}       # The stats, by meta category, and overall
    
    #-- Who's the overall winner?
    #@overall_winner = Item.where(:dialog_id=>@dialog_id).where(pwhere).includes(:participant=>{:metamap_node_participants=>:metamap_node}).includes(:item_rating_summary).order("value desc").first
    
    #-- All items/ratings, regardless of meta categories
    @data[0] = {}
    @data[0]['name'] = 'Total'
    @data[0]['items'] = {}     # All items in the dialog/period
    @data[0]['itemsproc'] = {}     # All items in the dialog/period
    @data[0]['ratings'] = {}     # All the ratings of those items
    @data[0]['num_raters'] = 0   # Number of raters
    @data[0]['num_int_items'] = 0   # Number of unique items with interest ratings
    @data[0]['num_app_items'] = 0   # Number of unique items with approval ratings
    @data[0]['num_interest'] = 0   # Number of interest votes
    @data[0]['num_approval'] = 0   # Number of approval votes
    @data[0]['tot_interest'] = 0   # Total interest
    @data[0]['tot_approval'] = 0   # Total approval
    @data[0]['avg_votes_int'] = 0   # Average number of interest votes
    @data[0]['avg_votes_app'] = 0   # Average number of approval votes
    @data[0]['avg_interest'] = 0   # Average interest rating
    @data[0]['avg_approval'] = 0   # Average approval rating
    @data[0]['sql'] = ''
    @data[0]['explanation'] = ''
    
    if @regmean
      @data[0]['explanation'] += "regression to the mean used.<br>"
    else
      @data[0]['explanation'] += "No regression to the mean used"  
    end    
        
    items = Item.where("items.dialog_id=#{@dialog_id}").where(pwhere).where(gwhere).where("is_first_in_thread=1").includes(:participant).includes(:item_rating_summary)
    
    @data[0]['sql'] = items.to_sql
        
    for item in items
      item_id = item.id
      poster_id = item.posted_by
      @data[0]['items'][item.id] = item
    end

    ratings = Rating.where("ratings.dialog_id=#{@dialog_id}").where(pwhere).where(gwhere).includes(:participant).includes(:item=>:item_rating_summary)
    
    item_int_uniq = {}
    item_app_uniq = {}
    for rating in ratings
      rating_id = rating.id
      item_id = rating.item_id
      rater_id = rating.participant_id
      if @data[0]['items'][item_id]
        #-- Only count if the item actually exists
        @data[0]['ratings'][rating.id] = rating
        @data[0]['num_raters'] += 1 if rating.approval or rating.interest
        @data[0]['num_interest'] += 1 if rating.interest
        @data[0]['num_approval'] += 1 if rating.approval
        @data[0]['tot_interest'] += rating.interest.to_i if rating.interest
        @data[0]['tot_approval'] += rating.approval.to_i if rating.approval
        item_int_uniq[item_id] = true if rating.interest
        item_app_uniq[item_id] = true if rating.approval
      end
    end
    @data[0]['num_int_items'] = item_int_uniq.length
    @data[0]['num_app_items'] = item_app_uniq.length
    if @data[0]['num_int_items'] > 0
      @data[0]['avg_votes_int'] = ( @data[0]['num_interest'] / @data[0]['num_int_items'] ).to_i
    end
    @data[0]['explanation'] += "#{@data[0]['num_int_items']} items have interest ratings by #{@data[0]['num_interest']} people, totalling #{@data[0]['tot_interest']}. Average # of votes per item: #{@data[0]['avg_votes_int']}<br>"
    if @data[0]['avg_votes_int'] > 20
      @data[0]['avg_votes_int'] = 20 
      @data[0]['explanation'] += "Average # of interest votes adjusted down to 20<br>" 
    end  
    if @data[0]['num_interest'] > 0
      @data[0]['avg_interest'] = 1.0 * @data[0]['tot_interest'] / @data[0]['num_interest']
      @data[0]['explanation'] += "Average interest: #{@data[0]['tot_interest']} / #{@data[0]['num_interest']} = #{@data[0]['avg_interest']}<br>"      
    else
      @data[0]['explanation'] += "Average interest: 0<br>"  
    end
    
    if @data[0]['num_app_items'] > 0
      @data[0]['avg_votes_app'] = ( @data[0]['num_approval'] / @data[0]['num_app_items'] ).to_i 
    end
    @data[0]['explanation'] += "#{@data[0]['num_app_items']} items have approval ratings by #{@data[0]['num_approval']} people, totalling #{@data[0]['tot_approval']}. Average # of votes per item: #{@data[0]['avg_votes_app']}<br>"
    if @data[0]['avg_votes_app'] > 20
      @data[0]['avg_votes_app'] = 20 
      @data[0]['explanation'] += "Average # of appoval votes adjusted down to 20<br>" 
    end  
    if @data[0]['num_approval'] > 0
      @data[0]['avg_approval'] = 1.0 * @data[0]['tot_approval'] / @data[0]['num_approval']
      @data[0]['explanation'] += "Average approval: #{@data[0]['tot_approval']} / #{@data[0]['num_approval']} = #{@data[0]['avg_approval']}<br>"      
    else
      @data[0]['explanation'] += "Average appoval: 0<br>"  
    end  

    #@data[0]['explanation'] += "avg_votes_int = #{@data[0]['num_interest']} / #{@data[0]['num_int_items']} = #{@data[0]['avg_votes_int']}<br>"
    #@data[0]['explanation'] += "avg_votes_app = #{@data[0]['num_approval']} / #{@data[0]['num_app_items']} = #{@data[0]['avg_votes_app']}<br>"
    #@data[0]['explanation'] += "avg_interest = #{@data[0]['tot_interest']} / #{@data[0]['num_interest']} = #{@data[0]['avg_interest']}<br>"
    #@data[0]['explanation'] += "avg_approval = #{@data[0]['tot_approval']} / #{@data[0]['num_approval']} = #{@data[0]['avg_approval']}<br>"
    
    @avg_votes_int = @data[0]['avg_votes_int']
    @avg_votes_app = @data[0]['avg_votes_app']
    @avg_interest = @data[0]['avg_interest']
    @avg_approval = @data[0]['avg_approval']
    
    @data[0]['items'].each do |item_id,item|
      iproc = {'id'=>item.id,'name'=>show_name_in_result(item,@dialog,@period),'subject'=>item.subject,'votes'=>0,'num_raters'=>0,'num_interest'=>0,'tot_interest'=>0,'avg_interest'=>0.0,'num_approval'=>0,'tot_approval'=>0,'avg_approval'=>0.0,'value'=>0.0,'int_0_count'=>0,'int_1_count'=>0,'int_2_count'=>0,'int_3_count'=>0,'int_4_count'=>0,'app_n3_count'=>0,'app_n2_count'=>0,'app_n1_count'=>0,'app_0_count'=>0,'app_p1_count'=>0,'app_p2_count'=>0,'app_p3_count'=>0,'controversy'=>0,'ratings'=>[]}
      @data[0]['ratings'].each do |rating_id,rating|
        if rating.item_id == item.id
          iproc['votes'] += 1
          iproc['num_raters'] += 1 if rating.approval or rating.interest
          if rating.interest
            iproc['num_interest'] += 1
            iproc['tot_interest'] += rating.interest.to_i
            iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
            case rating.interest.to_i
            when 0
              iproc['int_0_count'] += 1
            when 1
              iproc['int_1_count'] += 1
            when 2
              iproc['int_2_count'] += 1
            when 3
              iproc['int_3_count'] += 1
            when 4
              iproc['int_4_count'] += 1
            end  
          end
          if rating.approval
            iproc['num_approval'] += 1
            iproc['tot_approval'] += rating.approval.to_i
            iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
            case rating.approval.to_i
            when -3
              iproc['app_n3_count'] +=1   
            when -2
              iproc['app_n2_count'] +=1   
            when -1
              iproc['app_n1_count'] +=1   
            when 0
              iproc['app_0_count'] +=1   
            when 1
              iproc['app_p1_count'] +=1   
            when 2
              iproc['app_p2_count'] +=1   
            when 3
              iproc['app_p3_count'] +=1   
            end  
          end
          iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
          iproc['ratings'] << rating
        end
        iproc['ratingnoregmean'] = "Average interest: #{iproc['tot_interest']} total / #{iproc['num_interest']} ratings = #{iproc['avg_interest']}<br>" + "Average approval: #{iproc['tot_approval']} total / #{iproc['num_approval']} ratings = #{iproc['avg_approval']}<br>" + "Value: #{iproc['avg_interest']} interest * #{iproc['avg_approval']} approval = #{iproc['value']}<br>"
      end
      iproc['controversy'] = (1.0 * ( iproc['app_n3_count'] * (-3.0 - iproc['avg_approval'])**2 + iproc['app_n2_count'] * (-2.0 - iproc['avg_approval'])**2 + iproc['app_n1_count'] * (-1.0 - iproc['avg_approval'])**2 + iproc['app_0_count'] * (0.0 - iproc['avg_approval'])**2 + iproc['app_p1_count'] * (1.0 - iproc['avg_approval'])**2 + iproc['app_p2_count'] * (2.0 - iproc['avg_approval'])**2 + iproc['app_p3_count'] * (3.0 - iproc['avg_approval'])**2 ) / iproc['num_approval']) if iproc['num_approval'] != 0
      @data[0]['itemsproc'][item_id] = iproc
    end   
    if @regmean
      #-- Go through the items again and do a regression to the mean
      logger.info("dialogs#result regression to mean")
      @data[0]['items'].each do |item_id,item|
        iproc = @data[0]['itemsproc'][item_id]
        iproc['ratingwithregmean'] = ""
        if iproc['num_interest'] < @avg_votes_int and iproc['num_interest'] > 0
          old_num_interest = iproc['num_interest']
          old_tot_interest = iproc['tot_interest']
          iproc['tot_interest'] += (@avg_votes_int - iproc['num_interest']) * @avg_interest
          iproc['num_interest'] = @avg_votes_int
          iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
          iproc['ratingwithregmean'] += "int votes adjusted #{old_num_interest} -> #{iproc['num_interest']}. int total adjusted #{old_tot_interest} -> #{iproc['tot_interest']}<br>"
        end  
        if iproc['num_approval'] < @avg_votes_app and iproc['num_approval'] > 0
          old_num_approval = iproc['num_approval']
          old_tot_approval = iproc['tot_approval']
          iproc['tot_approval'] += (@avg_votes_app - iproc['num_approval']) * @avg_approval
          iproc['num_approval'] = @avg_votes_app
          iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
          iproc['ratingwithregmean'] += "app votes adjusted #{old_num_approval} -> #{iproc['num_approval']}. app total adjusted #{old_tot_approval} -> #{iproc['tot_approval']}<br>"
        end  
        iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
        iproc['ratingwithregmean'] += "Average interest: #{iproc['tot_interest']} total / #{iproc['num_interest']} ratings = #{iproc['avg_interest']}<br>" + "Average approval: #{iproc['tot_approval']} total / #{iproc['num_approval']} ratings = #{iproc['avg_approval']}<br>" + "Value: #{iproc['avg_interest']} interest * #{iproc['avg_approval']} approval = #{iproc['value']}<br>"
        @data[0]['itemsproc'][item_id] = iproc
      end
    end
    @data[0]['itemsproc'] = @data[0]['itemsproc'].sort {|a,b| [b[1]['value'],b[1]['votes']]<=>[a[1]['value'],a[1]['votes']]}

    if @data[0]['itemsproc'].length > 0
      @overall_winner_id = @data[0]['itemsproc'].first[1]['id']
      @overall_winner = @data[0]['items'][@overall_winner_id]
      logger.info("dialogs#result Overall winner: #{@overall_winner_id}") 
    else
      @overall_winner_id = nil
      @overall_winner = nil
      logger.info("dialogs#result No Overall winner") 
    end

    if @limit_group_id == 0
      #-- Stats by group
      @data['groups'] = {}
      for group in @dialog.groups
        group_id = group.id     
        @data['groups'][group_id] = {}
        @data['groups'][group_id]['name'] = 'Group:' + group.name
        @data['groups'][group_id]['items'] = {}     # All items posted by that group
        @data['groups'][group_id]['itemsproc'] = {}     # All items posted by that group
        @data['groups'][group_id]['ratings'] = {}     # All the ratings by that group
        @data['groups'][group_id]['num_raters'] = 0   # Number of raters
        @data['groups'][group_id]['num_int_items'] = 0   # Number of unique items with interest ratings
        @data['groups'][group_id]['num_app_items'] = 0   # Number of unique items with approval ratings
        @data['groups'][group_id]['num_interest'] = 0   # Number of interest votes
        @data['groups'][group_id]['num_approval'] = 0   # Number of approval votes
        @data['groups'][group_id]['tot_interest'] = 0   # Total interest
        @data['groups'][group_id]['tot_approval'] = 0   # Total approval
        @data['groups'][group_id]['avg_votes_int'] = 0   # Average number of interest votes
        @data['groups'][group_id]['avg_votes_app'] = 0   # Average number of approval votes
        @data['groups'][group_id]['avg_interest'] = 0   # Average interest rating
        @data['groups'][group_id]['avg_approval'] = 0   # Average approval rating

        items = Item.where("items.dialog_id=#{@dialog_id}").where(pwhere).where(:group_id=>group_id).where("is_first_in_thread=1").includes(:participant).includes(:item_rating_summary)

        for item in items
          item_id = item.id
          poster_id = item.posted_by
          @data['groups'][group_id]['items'][item.id] = item
        end

        ratings = Rating.where("ratings.dialog_id=#{@dialog_id}").where(pwhere).where(:group_id=>group_id).includes(:participant).includes(:item=>:item_rating_summary)

        item_int_uniq = {}
        item_app_uniq = {}
        for rating in ratings
          rating_id = rating.id
          item_id = rating.item_id
          rater_id = rating.participant_id
          @data['groups'][group_id]['ratings'][rating.id] = rating
          @data['groups'][group_id]['num_raters'] += 1 if rating.interest or rating.approval
          @data['groups'][group_id]['num_interest'] += 1 if rating.interest
          @data['groups'][group_id]['num_approval'] += 1 if rating.approval
          @data['groups'][group_id]['tot_interest'] += rating.interest.to_i if rating.interest
         @data['groups'][group_id]['tot_approval'] += rating.approval.to_i if rating.approval
          item_int_uniq[item_id] = true if rating.interest
          item_app_uniq[item_id] = true if rating.approval
        end
        @data['groups'][group_id]['num_int_items'] = item_int_uniq.length
        @data['groups'][group_id]['num_app_items'] = item_app_uniq.length

        @data['groups'][group_id]['avg_votes_int'] = ( @data['groups'][group_id]['num_interest'] / @data['groups'][group_id]['num_int_items'] ).to_i if @data['groups'][group_id]['num_int_items'] > 0
        @data['groups'][group_id]['avg_votes_app'] = ( @data['groups'][group_id]['num_approval'] / @data['groups'][group_id]['num_app_items'] ).to_i if @data['groups'][group_id]['num_app_items'] > 0
        @data['groups'][group_id]['avg_votes_int'] = 20 if @data['groups'][group_id]['avg_votes_int'] > 20
        @data['groups'][group_id]['avg_votes_app'] = 20 if @data['groups'][group_id]['avg_votes_app'] > 20
        @data['groups'][group_id]['avg_interest'] = 1.0 * @data['groups'][group_id]['tot_interest'] / @data['groups'][group_id]['num_interest'] if @data['groups'][group_id]['num_interest'] > 0
        @data['groups'][group_id]['avg_approval'] = 1.0 * @data['groups'][group_id]['tot_approval'] / @data['groups'][group_id]['num_approval'] if @data['groups'][group_id]['num_approval'] > 0

        @avg_votes_int = @data['groups'][group_id]['avg_votes_int']
        @avg_votes_app = @data['groups'][group_id]['avg_votes_app']
        @avg_interest = @data['groups'][group_id]['avg_interest']
        @avg_approval = @data['groups'][group_id]['avg_approval']

        @data['groups'][group_id]['items'].each do |item_id,item|
          iproc = {'id'=>item.id,'name'=>show_name_in_result(item,@dialog,@period),'subject'=>item.subject,'votes'=>0,'num_raters'=>0,'num_interest'=>0,'tot_interest'=>0,'avg_interest'=>0.0,'num_approval'=>0,'tot_approval'=>0,'avg_approval'=>0.0,'value'=>0.0,'int_0_count'=>0,'int_1_count'=>0,'int_2_count'=>0,'int_3_count'=>0,'int_4_count'=>0,'app_n3_count'=>0,'app_n2_count'=>0,'app_n1_count'=>0,'app_0_count'=>0,'app_p1_count'=>0,'app_p2_count'=>0,'app_p3_count'=>0,'controversy'=>0}
          @data['groups'][group_id]['ratings'].each do |rating_id,rating|
            if rating.item_id == item.id
              iproc['votes'] += 1
              iproc['num_raters'] += 1 if rating.interest or rating.approval
              if rating.interest
                iproc['num_interest'] += 1
                iproc['tot_interest'] += rating.interest.to_i
                iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
                case rating.interest.to_i
                when 0
                  iproc['int_0_count'] += 1
                when 1
                  iproc['int_1_count'] += 1
                when 2
                  iproc['int_2_count'] += 1
                when 3
                  iproc['int_3_count'] += 1
                when 4
                  iproc['int_4_count'] += 1
                end  
              end
              if rating.approval
                iproc['num_approval'] += 1
                iproc['tot_approval'] += rating.approval.to_i
                iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
                case rating.approval.to_i
                when -3
                  iproc['app_n3_count'] +=1   
                when -2
                  iproc['app_n2_count'] +=1   
                when -1
                  iproc['app_n1_count'] +=1   
                when 0
                  iproc['app_0_count'] +=1   
                when 1
                  iproc['app_p1_count'] +=1   
                when 2
                  iproc['app_p2_count'] +=1   
                when 3
                  iproc['app_p3_count'] +=1   
                end  
              end
              iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
            end
          end
          iproc['controversy'] = (1.0 * ( iproc['app_n3_count'] * (-3.0 - iproc['avg_approval'])**2 + iproc['app_n2_count'] * (-2.0 - iproc['avg_approval'])**2 + iproc['app_n1_count'] * (-1.0 - iproc['avg_approval'])**2 + iproc['app_0_count'] * (0.0 - iproc['avg_approval'])**2 + iproc['app_p1_count'] * (1.0 - iproc['avg_approval'])**2 + iproc['app_p2_count'] * (2.0 - iproc['avg_approval'])**2 + iproc['app_p3_count'] * (3.0 - iproc['avg_approval'])**2 ) / iproc['num_approval']) if iproc['num_approval'] != 0
          @data['groups'][group_id]['itemsproc'][item_id] = iproc
        end   
        if @regmean
          #-- Go through the items again and do a regression to the mean
          @data['groups'][group_id]['items'].each do |item_id,item|
            iproc = @data['groups'][group_id]['itemsproc'][item_id]
            if iproc['num_interest'] < @avg_votes_int and iproc['num_interest'] > 0
              iproc['tot_interest'] += (@avg_votes_int - iproc['num_interest']) * @avg_interest
              iproc['num_interest'] = @avg_votes_int
              iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
            end  
            if iproc['num_approval'] < @avg_votes_app and iproc['num_approval'] > 0
              iproc['tot_approval'] += (@avg_votes_app - iproc['num_approval']) * @avg_approval
              iproc['num_approval'] = @avg_votes_app
              iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
            end  
            iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
            @data['groups'][group_id]['itemsproc'][item_id] = iproc
          end
        end
        @data['groups'][group_id]['itemsproc'] = @data['groups'][group_id]['itemsproc'].sort {|a,b| [b[1]['value'],b[1]['votes']]<=>[a[1]['value'],a[1]['votes']]}
      end  #-- groups
    end #-- If no specific group is selected

    #-- And now we'll look at meta categories    
    
    #@metamaps = Metamap.joins(:dialogs).where("dialogs.id=#{@dialog_id}")
    # temporarily we hardcode it:
    @metamaps = Metamap.where(:id=>[3,5])

    #r = Participant.joins(:groups=>:dialogs).joins(:metamap_nodes).where("dialogs.id=3").where("metamap_nodes.metamap_id=2").select("participants.id,first_name,metamap_nodes.name as metamap_node_name")

    #-- Find how many people and items for each metamap_node
    for metamap in @metamaps

      metamap_id = metamap.id

      @data[metamap.id] = {}
      @data[metamap.id]['name'] = metamap.name
      @data[metamap.id]['nodes'] = {}  # All nodes that have been used, for posting or rating, with their names
      @data[metamap.id]['postedby'] = { # stats for what was posted by people in those meta categories
        'nodes' => {}
      }    
      @data[metamap.id]['ratedby'] = {     # stats for what was rated by people in those meta categories
        'nodes' => {}
      }
      @data[metamap.id]['matrix'] = {      # stats for posted by meta cats crossed by rated by metacats
        'post_rate' => {},
        'rate_post' => {}
      }
      @data[metamap.id]['items'] = {}     # To keep track of the items marked with that meta cat
      @data[metamap.id]['ratings'] = {}     # Keep track of the ratings of items in that meta cat

      #-- Everything posted, with metanode info
      items = Item.where("items.dialog_id=#{@dialog_id}").where(pwhere).where(gwhere).where("is_first_in_thread=1").includes(:participant=>{:metamap_node_participants=>:metamap_node}).includes(:item_rating_summary).where("metamap_node_participants.metamap_id=#{metamap_id}")
      
      #-- Everything rated, with metanode info
      ratings = Rating.where("ratings.dialog_id=#{@dialog_id}").where(pwhere).where(gwhere).includes(:participant=>{:metamap_node_participants=>:metamap_node}).includes(:item=>:item_rating_summary).where("metamap_node_participants.metamap_id=#{metamap_id}")
      
      #-- Going through everything posted, group by meta node of poster
      for item in items
        item_id = item.id
        poster_id = item.posted_by
        metamap_node_id = item.participant.metamap_node_participants[0].metamap_node_id
        metamap_node_name = item.participant.metamap_node_participants[0].metamap_node.name_as_group ? item.participant.metamap_node_participants[0].metamap_node.name_as_group : item.participant.metamap_node_participants[0].metamap_node.name
        
        @data[metamap.id]['items'][item.id] = metamap_node_id

        logger.info("dialogs#result item ##{item.id} poster meta:#{metamap_node_id}/#{metamap_node_name}") 

        if not @data[metamap.id]['nodes'][metamap_node_id]
          #@data[metamap.id]['nodes'][metamap_node_id] = metamap_node_name
          @data[metamap.id]['nodes'][metamap_node_id] = [metamap_node_name,item.participant.metamap_node_participants[0].metamap_node]
          logger.info("dialogs#result @data[#{metamap.id}]['nodes'][#{metamap_node_id}] = #{metamap_node_name}")
        end
        if not @data[metamap.id]['postedby']['nodes'][metamap_node_id]
          @data[metamap.id]['postedby']['nodes'][metamap_node_id] = {
            'name' => item.participant.metamap_node_participants[0].metamap_node.name,
            'items' => {},
            'itemsproc' => {},
            'posters' => {},
            'ratings' => {},
            'num_raters' => 0,
            'num_int_items' => 0,
            'num_app_items' => 0,
            'num_interest' => 0,
            'num_approval' => 0,
            'tot_interest' => 0,
            'tot_approval' => 0,
            'avg_votes_int' => 0,
            'avg_votes_app' => 0,
            'avg_interest' => 0,
            'avg_approval' => 0      
          }
        end
        if not @data[metamap.id]['matrix']['post_rate'][metamap_node_id]
          @data[metamap.id]['matrix']['post_rate'][metamap_node_id] = {}
        end
        @data[metamap.id]['postedby']['nodes'][metamap_node_id]['items'][item_id] = item
        @data[metamap.id]['postedby']['nodes'][metamap_node_id]['posters'][poster_id] = item.participant
      end

      #-- Going through everything rated, group by meta node of rater
      for rating in ratings
        rating_id = rating.id
        item_id = rating.item_id
        rater_id = rating.participant_id
        metamap_node_id = rating.participant.metamap_node_participants[0].metamap_node_id
        metamap_node_name = rating.participant.metamap_node_participants[0].metamap_node.name_as_group ? rating.participant.metamap_node_participants[0].metamap_node.name_as_group : rating.participant.metamap_node_participants[0].metamap_node.name

        logger.info("dialogs#result rating ##{rating_id} of item ##{item_id} rater meta:#{metamap_node_id}/#{metamap_node_name}") 
       
        if not @data[0]['items'][item_id]
          logger.info("dialogs#result item ##{item_id} doesn't exist. Skipping.")
          next
        end

        if not @data[metamap.id]['nodes'][metamap_node_id]
          #@data[metamap.id]['nodes'][metamap_node_id] = metamap_node_name
          @data[metamap.id]['nodes'][metamap_node_id] = [metamap_node_name,rating.participant.metamap_node_participants[0].metamap_node]
          #logger.info("dialogs#result @data[#{metamap.id}]['nodes'][#{metamap_node_id}] = #{metamap_node_name}")
        end
        @data[metamap.id]['ratings'][rating.id] = metamap_node_id
        if not @data[metamap.id]['ratedby']['nodes'][metamap_node_id]
          @data[metamap.id]['ratedby']['nodes'][metamap_node_id] = {
            'name' => rating.participant.metamap_node_participants[0].metamap_node.name,
            'items' => {},
            'itemsproc' => {},
            'raters' => {},
            'ratings' => {},
            'num_raters' => 0,
            'num_int_items' => 0,
            'num_app_items' => 0,
            'num_interest' => 0,
            'num_approval' => 0,
            'tot_interest' => 0,
            'tot_approval' => 0,
            'avg_votes_int' => 0,
            'avg_votes_app' => 0,
            'avg_interest' => 0,
            'avg_approval' => 0      
          }
        end
        if not @data[metamap.id]['matrix']['rate_post'][metamap_node_id]
          @data[metamap.id]['matrix']['rate_post'][metamap_node_id] = {}
        end
        @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['items'][item_id] = rating.item
        @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['raters'][rater_id] = rating.participant
        @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['ratings'][rating_id] = rating
        item_metamap_node_id = @data[metamap.id]['items'][item_id]
        
        if not @data[metamap.id]['nodes'][item_metamap_node_id]
          logger.info("dialogs#result @data[#{metamap.id}]['nodes'][#{item_metamap_node_id}] doesn't exist. Skipping.")
          next
        end  

        @data[metamap.id]['postedby']['nodes'][item_metamap_node_id]['ratings'][rating_id] = rating
        if not @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id]
          @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id] = {
            'post_name' => '',
            'rate_name' => '',
            'items' => {},
            'itemsproc' => {},
            'ratings' => {},
            'num_raters' => 0,
            'num_int_items' => 0,
            'num_app_items' => 0,
            'num_interest' => 0,
            'num_approval' => 0,
            'tot_interest' => 0,
            'tot_approval' => 0,
            'avg_votes_int' => 0,
            'avg_votes_app' => 0,
            'avg_interest' => 0,
            'avg_approval' => 0      
          }
        end
        #-- Store a matrix crossing the item's meta with the rater's meta (within a particular metamap, e.g. gender)
        @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id]['ratings'][rating_id] = rating
        @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id]['items'][item_id] = rating.item
        @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id]['post_name'] = @data[metamap.id]['nodes'][item_metamap_node_id][0]
        @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id]['rate_name'] = metamap_node_name
      end  # ratings
      
      #-- nodes_sorted moved from here

      #-- Adding up stats for postedby items. I.e. items posted by people in that meta.
      @data[metamap.id]['postedby']['nodes'].each do |metamap_node_id,mdata|
        # {'num_items'=>0,'num_ratings'=>0,'avg_rating'=>0.0,'num_interest'=>0,'num_approval'=>0,'avg_appoval'=>0.0,'avg_interest'=>0.0,'avg_value'=>0,'value_winner'=>0}
        item_int_uniq = {}
        item_app_uniq = {}
        mdata['items'].each do |item_id,item|
          iproc = {'id'=>item.id,'name'=>show_name_in_result(item,@dialog,@period),'subject'=>item.subject,'votes'=>0,'num_raters'=>0,'num_interest'=>0,'tot_interest'=>0,'avg_interest'=>0.0,'num_approval'=>0,'tot_approval'=>0,'avg_approval'=>0.0,'value'=>0.0,'int_0_count'=>0,'int_1_count'=>0,'int_2_count'=>0,'int_3_count'=>0,'int_4_count'=>0,'app_n3_count'=>0,'app_n2_count'=>0,'app_n1_count'=>0,'app_0_count'=>0,'app_p1_count'=>0,'app_p2_count'=>0,'app_p3_count'=>0,'controversy'=>0,'ratings'=>[]}
          mdata['ratings'].each do |rating_id,rating|
            if rating.item_id == item.id
              iproc['votes'] += 1
              iproc['num_raters'] += 1
              if rating.interest
                iproc['num_interest'] += 1
                iproc['tot_interest'] += rating.interest
                iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
                case rating.interest.to_i
                when 0
                  iproc['int_0_count'] += 1
                when 1
                  iproc['int_1_count'] += 1
                when 2
                  iproc['int_2_count'] += 1
                when 3
                  iproc['int_3_count'] += 1
                when 4
                  iproc['int_4_count'] += 1
                end  
              end
              if rating.approval
                iproc['num_approval'] += 1
                iproc['tot_approval'] += rating.approval
                iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
                case rating.approval.to_i
                when -3
                  iproc['app_n3_count'] +=1   
                when -2
                  iproc['app_n2_count'] +=1   
                when -1
                  iproc['app_n1_count'] +=1   
                when 0
                  iproc['app_0_count'] +=1   
                when 1
                  iproc['app_p1_count'] +=1   
                when 2
                  iproc['app_p2_count'] +=1   
                when 3
                  iproc['app_p3_count'] +=1   
                end  
              end
              iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
              iproc['ratings'] << rating
              
              #-- Need this for regmean
              @data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_raters'] += 1 if rating.interest or rating.approval
              @data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_interest'] += 1 if rating.interest
              @data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_approval'] += 1 if rating.approval
              @data[metamap.id]['postedby']['nodes'][metamap_node_id]['tot_interest'] += rating.interest.to_i if rating.interest
              @data[metamap.id]['postedby']['nodes'][metamap_node_id]['tot_approval'] += rating.approval.to_i if rating.approval
              item_int_uniq[item_id] = true if rating.interest
              item_app_uniq[item_id] = true if rating.approval
              
            end
          end
          iproc['controversy'] = (1.0 * ( iproc['app_n3_count'] * (-3.0 - iproc['avg_approval'])**2 + iproc['app_n2_count'] * (-2.0 - iproc['avg_approval'])**2 + iproc['app_n1_count'] * (-1.0 - iproc['avg_approval'])**2 + iproc['app_0_count'] * (0.0 - iproc['avg_approval'])**2 + iproc['app_p1_count'] * (1.0 - iproc['avg_approval'])**2 + iproc['app_p2_count'] * (2.0 - iproc['avg_approval'])**2 + iproc['app_p3_count'] * (3.0 - iproc['avg_approval'])**2 ) / iproc['num_approval']) if iproc['num_approval'] != 0
          @data[metamap.id]['postedby']['nodes'][metamap_node_id]['itemsproc'][item_id] = iproc
        end
        
        @data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_int_items'] = item_int_uniq.length
        @data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_app_items'] = item_app_uniq.length
        @data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_votes_int'] = ( @data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_interest'] / @data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_int_items'] ).to_i if @data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_int_items'] > 0
        @data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_votes_app'] = ( @data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_approval'] / @data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_app_items'] ).to_i if @data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_app_items'] > 0
        @data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_votes_int'] = 20 if @data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_votes_int'] > 20
        @data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_votes_app'] = 20 if @data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_votes_app'] > 20
        @data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_interest'] = 1.0 * @data[metamap.id]['postedby']['nodes'][metamap_node_id]['tot_interest'] / @data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_interest'] if @data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_interest'] > 0
        @data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_approval'] = 1.0 * @data[metamap.id]['postedby']['nodes'][metamap_node_id]['tot_approval'] / @data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_approval'] if @data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_approval'] > 0
        @avg_votes_int = @data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_votes_int']
        @avg_votes_app = @data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_votes_app']
        @avg_interest  = @data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_interest']
        @avg_approval  = @data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_approval']
        
        if @regmean
          #-- Go through the items again and do a regression to the mean          
          mdata['items'].each do |item_id,item|
            iproc = @data[metamap.id]['postedby']['nodes'][metamap_node_id]['itemsproc'][item_id]
            if iproc['num_interest'] < @avg_votes_int and iproc['num_interest'] > 0
              iproc['tot_interest'] += (@avg_votes_int - iproc['num_interest']) * @avg_interest
              iproc['num_interest'] = @avg_votes_int
              iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
            end  
            if iproc['num_approval'] < @avg_votes_app and iproc['num_approval'] > 0
              iproc['tot_approval'] += (@avg_votes_app - iproc['num_approval']) * @avg_approval
              iproc['num_approval'] = @avg_votes_app
              iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
            end  
            iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
            @data[metamap.id]['postedby']['nodes'][metamap_node_id]['itemsproc'][item_id] = iproc
          end
        end
        #@data[metamap.id]['postedby']['nodes'][metamap_node_id]['itemsproc'] = @data[metamap.id]['postedby']['nodes'][metamap_node_id]['itemsproc'].sort {|a,b| b[1]['value']<=>a[1]['value']}
        @data[metamap.id]['postedby']['nodes'][metamap_node_id]['itemsproc'] = @data[metamap.id]['postedby']['nodes'][metamap_node_id]['itemsproc'].sort {|a,b| [b[1]['value'],b[1]['votes']]<=>[a[1]['value'],a[1]['votes']]}

      end
      
      #-- Adding up stats for ratedby items. I.e. items rated by people in that meta.
      @data[metamap.id]['ratedby']['nodes'].each do |metamap_node_id,mdata|
        # {'num_items'=>0,'num_ratings'=>0,'avg_rating'=>0.0,'num_interest'=>0,'num_approval'=>0,'avg_appoval'=>0.0,'avg_interest'=>0.0,'avg_value'=>0,'value_winner'=>0}
        item_int_uniq = {}
        item_app_uniq = {}
        mdata['items'].each do |item_id,item|
          iproc = {'id'=>item.id,'name'=>show_name_in_result(item,@dialog,@period),'subject'=>item.subject,'votes'=>0,'num_raters'=>0,'num_interest'=>0,'tot_interest'=>0,'avg_interest'=>0.0,'num_approval'=>0,'tot_approval'=>0,'avg_approval'=>0.0,'value'=>0.0,'int_0_count'=>0,'int_1_count'=>0,'int_2_count'=>0,'int_3_count'=>0,'int_4_count'=>0,'app_n3_count'=>0,'app_n2_count'=>0,'app_n1_count'=>0,'app_0_count'=>0,'app_p1_count'=>0,'app_p2_count'=>0,'app_p3_count'=>0,'controversy'=>0,'ratings'=>[]}
          mdata['ratings'].each do |rating_id,rating|
            if rating.item_id == item.id
              iproc['votes'] += 1
              iproc['num_raters'] +=1
              if rating.interest
                iproc['num_interest'] += 1
                iproc['tot_interest'] += rating.interest.to_i
                iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
                case rating.interest.to_i
                when 0
                  iproc['int_0_count'] += 1
                when 1
                  iproc['int_1_count'] += 1
                when 2
                  iproc['int_2_count'] += 1
                when 3
                  iproc['int_3_count'] += 1
                when 4
                  iproc['int_4_count'] += 1
                end  
              end
              if rating.approval
                iproc['num_approval'] += 1
                iproc['tot_approval'] += rating.approval.to_i
                iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
                case rating.approval.to_i
                when -3
                  iproc['app_n3_count'] +=1   
                when -2
                  iproc['app_n2_count'] +=1   
                when -1
                  iproc['app_n1_count'] +=1   
                when 0
                  iproc['app_0_count'] +=1   
                when 1
                  iproc['app_p1_count'] +=1   
                when 2
                  iproc['app_p2_count'] +=1   
                when 3
                  iproc['app_p3_count'] +=1   
                end  
              end
              iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
              iproc['ratings'] << rating
              
              #-- Need this for regmean
              @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_raters'] += 1 if rating.interest or rating.approval
              @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_interest'] += 1 if rating.interest
              @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_approval'] += 1 if rating.approval
              @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['tot_interest'] += rating.interest.to_i if rating.interest
              @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['tot_approval'] += rating.approval.to_i if rating.approval
              item_int_uniq[item_id] = true if rating.interest
              item_app_uniq[item_id] = true if rating.approval
              
            end
          end
          iproc['controversy'] = (1.0 * ( iproc['app_n3_count'] * (-3.0 - iproc['avg_approval'])**2 + iproc['app_n2_count'] * (-2.0 - iproc['avg_approval'])**2 + iproc['app_n1_count'] * (-1.0 - iproc['avg_approval'])**2 + iproc['app_0_count'] * (0.0 - iproc['avg_approval'])**2 + iproc['app_p1_count'] * (1.0 - iproc['avg_approval'])**2 + iproc['app_p2_count'] * (2.0 - iproc['avg_approval'])**2 + iproc['app_p3_count'] * (3.0 - iproc['avg_approval'])**2 ) / iproc['num_approval']) if iproc['num_approval'] != 0
          @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['itemsproc'][item_id] = iproc
        end    
        
        @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_int_items'] = item_int_uniq.length
        @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_app_items'] = item_app_uniq.length
        @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_votes_int'] = ( @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_interest'] / @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_int_items'] ).to_i if @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_int_items'] > 0
        @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_votes_app'] = ( @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_approval'] / @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_app_items'] ).to_i if @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_app_items'] > 0
        @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_votes_int'] = 20 if @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_votes_int'] > 20
        @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_votes_app'] = 20 if @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_votes_app'] > 20
        @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_interest'] = 1.0 * @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['tot_interest'] / @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_interest'] if @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_interest'] > 0
        @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_approval'] = 1.0 * @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['tot_approval'] / @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_approval'] if @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_approval'] > 0
        @avg_votes_int = @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_votes_int']
        @avg_votes_app = @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_votes_app']
        @avg_interest  = @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_interest']
        @avg_approval  = @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_approval']
            
        if @regmean
          #-- Go through the items again and do a regression to the mean
          mdata['items'].each do |item_id,item|
            iproc = @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['itemsproc'][item_id]
            if iproc['num_interest'] < @avg_votes_int and iproc['num_interest'] > 0
              iproc['tot_interest'] += (@avg_votes_int - iproc['num_interest']) * @avg_interest
              iproc['num_interest'] = @avg_votes_int
              iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
            end  
            if iproc['num_approval'] < @avg_votes_app and iproc['num_approval'] > 0
              iproc['tot_approval'] += (@avg_votes_app - iproc['num_approval']) * @avg_approval
              iproc['num_approval'] = @avg_votes_app
              iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
            end  
            iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
            @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['itemsproc'][item_id] = iproc
          end
        end
        @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['itemsproc'] = @data[metamap.id]['ratedby']['nodes'][metamap_node_id]['itemsproc'].sort {|a,b| [b[1]['value'],b[1]['votes']]<=>[a[1]['value'],a[1]['votes']]}
      end
      
      #-- Adding up matrix stats
      @data[metamap.id]['matrix']['post_rate'].each do |item_metamap_node_id,rdata|
        #-- Going through all metas with items that have been rated
        rdata.each do |rate_metamap_node_id,mdata|
          #-- Going through all the metas that have rated items in that meta (all within a particular metamap, like gender)
          item_int_uniq = {}
          item_app_uniq = {}
          mdata['items'].each do |item_id,item|
            #-- Going through the items of the second meta that have rated the first meta
            iproc = {'id'=>item.id,'name'=>show_name_in_result(item,@dialog,@period),'subject'=>item.subject,'votes'=>0,'num_raters'=>0,'num_interest'=>0,'tot_interest'=>0,'avg_interest'=>0.0,'num_approval'=>0,'tot_approval'=>0,'avg_approval'=>0.0,'value'=>0.0,'int_0_count'=>0,'int_1_count'=>0,'int_2_count'=>0,'int_3_count'=>0,'int_4_count'=>0,'app_n3_count'=>0,'app_n2_count'=>0,'app_n1_count'=>0,'app_0_count'=>0,'app_p1_count'=>0,'app_p2_count'=>0,'app_p3_count'=>0,'controversy'=>0,'rateapproval'=>0,'rateinterest'=>0,'ratings'=>[]}
            mdata['ratings'].each do |rating_id,rating|
              if rating.item_id == item.id
                iproc['votes'] += 1
                if rating.interest
                  iproc['num_interest'] += 1
                  iproc['tot_interest'] += rating.interest.to_i
                  iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
                  case rating.interest.to_i
                  when 0
                    iproc['int_0_count'] += 1
                  when 1
                    iproc['int_1_count'] += 1
                  when 2
                    iproc['int_2_count'] += 1
                  when 3
                    iproc['int_3_count'] += 1
                  when 4
                    iproc['int_4_count'] += 1
                  end  
                end
                if rating.approval                
                  iproc['num_approval'] += 1
                  iproc['tot_approval'] += rating.approval.to_i
                  iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
                  case rating.approval.to_i
                  when -3
                    iproc['app_n3_count'] +=1   
                  when -2
                    iproc['app_n2_count'] +=1   
                  when -1
                    iproc['app_n1_count'] +=1   
                  when 0
                    iproc['app_0_count'] +=1   
                  when 1
                    iproc['app_p1_count'] +=1   
                  when 2
                    iproc['app_p2_count'] +=1   
                  when 3
                    iproc['app_p3_count'] +=1   
                  end  
                end
                iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
                iproc['num_raters'] += 1
                iproc['ratingnoregmean'] = "Average interest: #{iproc['tot_interest']} total / #{iproc['num_interest']} ratings = #{iproc['avg_interest']}<br>" + "Average approval: #{iproc['tot_approval']} total / #{iproc['num_approval']} ratings = #{iproc['avg_approval']}<br>" + "Value: #{iproc['avg_interest']} interest * #{iproc['avg_approval']} approval = #{iproc['value']}"
                iproc['ratings'] << rating
                
                #-- Need this for regmean
                @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_raters'] += 1 if rating.interest or rating.approval
                @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_interest'] += 1 if rating.interest
                @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_approval'] += 1 if rating.approval
                @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['tot_interest'] += rating.interest.to_i if rating.interest
                @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['tot_approval'] += rating.approval.to_i if rating.approval
                item_int_uniq[item_id] = true if rating.interest
                item_app_uniq[item_id] = true if rating.approval
                
              end
            end
            iproc['controversy'] = (1.0 * ( iproc['app_n3_count'] * (-3.0 - iproc['avg_approval'])**2 + iproc['app_n2_count'] * (-2.0 - iproc['avg_approval'])**2 + iproc['app_n1_count'] * (-1.0 - iproc['avg_approval'])**2 + iproc['app_0_count'] * (0.0 - iproc['avg_approval'])**2 + iproc['app_p1_count'] * (1.0 - iproc['avg_approval'])**2 + iproc['app_p2_count'] * (2.0 - iproc['avg_approval'])**2 + iproc['app_p3_count'] * (3.0 - iproc['avg_approval'])**2 ) / iproc['num_approval']) if iproc['num_approval'] != 0
            @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['itemsproc'][item_id] = iproc
          end
          
          @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_int_items'] = item_int_uniq.length
          @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_app_items'] = item_app_uniq.length
          @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_votes_int'] = ( @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_interest'] / @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_int_items'] ).to_i if @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_int_items'] > 0
          @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_votes_app'] = ( @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_approval'] / @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_app_items'] ).to_i if @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_app_items'] > 0
          @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_votes_int'] = 20 if @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_votes_int'] > 20
          @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_votes_app'] = 20 if @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_votes_app'] > 20
          @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_interest'] = 1.0 * @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['tot_interest'] / @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_interest'] if @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_interest'] > 0
          @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_approval'] = 1.0 * @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['tot_approval'] / @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_approval'] if @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_approval'] > 0
          @avg_votes_int = @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_votes_int']
          @avg_votes_app = @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_votes_app']
          @avg_interest  = @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_interest']
          @avg_approval  = @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_approval']
          #if metamap.id == 3
          #  logger.info("dialogs#result @data[#{metamap.id}]['matrix']['post_rate'][#{item_metamap_node_id}][#{rate_metamap_node_id}]: #{@data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id].inspect}")
          #end
          
          if @regmean
            #-- Go through the items again and do a regression to the mean
            mdata['items'].each do |item_id,item|
              iproc = @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['itemsproc'][item_id]
              iproc['ratingwithregmean'] = ''
              if iproc['num_interest'] < @avg_votes_int and iproc['num_interest'] > 0
                old_num_interest = iproc['num_interest']
                old_tot_interest = iproc['tot_interest']
                iproc['tot_interest'] += (@avg_votes_int - iproc['num_interest']) * @avg_interest
                iproc['num_interest'] = @avg_votes_int
                iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
                iproc['ratingwithregmean'] += "int votes adjusted #{old_num_interest} -> #{iproc['num_interest']}. int total adjusted #{old_tot_interest} -> #{iproc['tot_interest']}<br>"
              end  
              if iproc['num_approval'] < @avg_votes_app and iproc['num_approval'] > 0
                old_num_approval = iproc['num_approval']
                old_tot_approval = iproc['tot_approval']
                iproc['tot_approval'] += (@avg_votes_app - iproc['num_approval']) * @avg_approval
                iproc['num_approval'] = @avg_votes_app
                iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
                iproc['ratingwithregmean'] += "app votes adjusted #{old_num_approval} -> #{iproc['num_approval']}. app total adjusted #{old_tot_approval} -> #{iproc['tot_approval']}<br>"
              end  
              iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
              iproc['ratingwithregmean'] += "Average interest: #{iproc['tot_interest']} total / #{iproc['num_interest']} ratings = #{iproc['avg_interest']}<br>" + "Average approval: #{iproc['tot_approval']} total / #{iproc['num_approval']} ratings = #{iproc['avg_approval']}<br>" + "Value: #{iproc['avg_interest']} interest * #{iproc['avg_approval']} approval = #{iproc['value']}"
              @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['itemsproc'][item_id] = iproc
            end
          end
          @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['itemsproc'] = @data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['itemsproc'].sort {|a,b| [b[1]['value'],b[1]['votes']]<=>[a[1]['value'],a[1]['votes']]}

        end
      end
      
      if ((@short_full == 'gender' and metamap.id == 3) or (@short_full == 'age' and metamap.id == 5))
        #-- We'd want nodes in order of value of the top item. Hm, that's tricky
      	for metamap_node_id,minfo in @data[metamap.id]['nodes']
      		metamap_node_name = minfo[0]
      		metamap_node = minfo[1]
      		@data[metamap.id]['nodes'][metamap_node_id][2] = 0
          if  @data[metamap.id]['postedby']['nodes'][metamap_node_id] and  @data[metamap.id]['postedby']['nodes'][metamap_node_id]['items'].length > 0
      			if @data[metamap.id]['matrix']['post_rate'][metamap_node_id].length > 0
        			for rate_metamap_node_id,rdata in @data[metamap.id]['matrix']['post_rate'][metamap_node_id]
        			  if rate_metamap_node_id == metamap_node_id
          				for item_id,i in @data[metamap.id]['matrix']['post_rate'][metamap_node_id][rate_metamap_node_id]['itemsproc']
          					item = @data[0]['items'][item_id]
                    iproc = @data[0]['itemsproc'][item_id]
                    #-- It should really be by iproc['value'] but somehow that doesn't work.
                    @data[metamap.id]['nodes'][metamap_node_id][2] = item.value
                		break
                  end
                end
              end
            end
          end
        end            
        @data[metamap.id]['nodes_sorted'] = @data[metamap.id]['nodes'].sort {|a,b| [b[1][2],a[1][1].sortorder,a[1][0]]<=>[a[1][2],b[1][1].sortorder,b[1][0]]}
      else
        #-- Put nodes in sorting order and/or alphabetical order
        #@data[metamap.id]['nodes_sorted'] = @data[metamap.id]['nodes'].sort {|a,b| a[1]<=>b[1]}
        @data[metamap.id]['nodes_sorted'] = @data[metamap.id]['nodes'].sort {|a,b| [a[1][1].sortorder,a[1][0]]<=>[b[1][1].sortorder,b[1][0]]}
      end

    end # metamaps
    
  end
  
  def result2
    #-- More simple version
    result
  end
  
  def results
    #-- List of voting results that apply to the current group. Current dialog is of no importance.
    #-- This should maybe have been in the groups controller, rather than here.
    @section = 'results'
    @group_id = session[:group_id]

    #-- Is this an admin?
    @is_group_admin = false
    @group = Group.find_by_id(@group_id)
    @group_participant = GroupParticipant.where(:participant_id=>current_participant.id).where(:group_id=>@group_id).first
    if @group_participant and @group_participant.moderator
      @is_group_admin = true
    elsif session[:is_hub_admin] or session[:is_sysadmin]   
      @is_group_admin = true
    end

    #-- What dialogs is the group in?
    dialog_ids = @group.dialogs.collect{|d| d.id}
    
    today = Time.now
    
    @periods = Period.where("dialog_id in (?)",dialog_ids)
    #if not @is_group_admin
    #  #-- Only (group) admins can see periods that aren't done
    #  @periods = @periods.where("endrating IS NOT NULL").where("endrating<?",today)
    #end

    update_last_url
    update_prefix
    
  end
  
  def get_default
    #-- Return a particular default template, e.g. invite, member, import
    which = params[:which]
    render :partial=>"#{which}_default", :layout=>false
  end
  
  def test_template
    #-- Show a template with the liquid macros filled in
    which = params[:which]
    @dialog_id = params[:id]
    @dialog = Dialog.find_by_id(@dialog_id)
    @group_id = session[:group_id].to_i
    @group = Group.find_by_id(@group_id) if @group_id > 0
    @dialog_group = DialogGroup.where("group_id=#{@group_id} and dialog_id=#{@dialog_id}").first
    if @dialog.shortname.to_s != "" and @group and @group.shortname.to_s != ""
  		@domain =  "#{@dialog.shortname}.#{@group.shortname}.#{ROOTDOMAIN}"
  	elsif @dialog.shortname.to_s != ""
  		@domain =  "#{@dialog.shortname}.#{ROOTDOMAIN}"
  	else
  		@domain = "#{BASEDOMAIN}"
  	end
    @logo = "https://#{BASEDOMAIN}#{@dialog.logo.url}" if @dialog.logo.exists?
    @participant = current_participant
    @email = @participant.email
    @name = @participant.name
    @countries = Geocountry.order(:name).select([:name,:iso])
    @meta = []
    metamaps = @group.metamaps
    for metamap in metamaps
      #m = OpenStruct.new
      m = {}
      m['id'] = metamap[0]
      m['name'] = metamap[1]
      m['val'] = params["meta_#{metamap[0]}"].to_i
      m['nodes'] = [{'id'=>0,'name'=>'* choose *'}]
      MetamapNode.where(:metamap_id=>m['id']).order(:sortorder,:name).each do |node|
        #n = OpenStruct.new
        n = {}
        n['id'] = node.id
        n['name'] = node.name
        m['nodes'] << n
      end
      @meta << m
    end
    
    cdata = {}
    cdata['group'] = @group if @group
    cdata['dialog'] = @dialog if @dialog
    cdata['group_logo'] = "https://#{BASEDOMAIN}#{@group.logo.url}" if @group.logo.exists?
    cdata['dialog_logo'] = "https://#{BASEDOMAIN}#{@dialog.logo.url}" if @dialog.logo.exists?
    cdata['dialog_group'] = @dialog_group if @dialog_group
    cdata['participant'] = @participant
    cdata['recipient'] = @participant
    cdata['domain'] = @domain
    cdata['password'] = '[#@$#$%$^]'
    cdata['confirmlink'] = "https://#{@domain}/front/confirm?code=#{@participant.confirmation_token}&group_id=#{@group_id}"
    cdata['logo'] = @logo if @logo
    cdata['countries'] = @countries
    cdata['meta'] = @meta
    cdata['message'] = '[Custom message]'    
    cdata['subject'] = '[Subject line]'
      
    if @dialog.send("#{which}_template").to_s != ""
      template_content = render_to_string(plain: @dialog.send("#{which}_template"), layout: false)      
    else
      template_content = render_to_string(:partial=>"#{which}_default",:layout=>false)
    end      
    template = Liquid::Template.parse(template_content)
    render html: template.render(cdata).html_safe, layout: false    
  end

  def get_period_default
    #-- Return a particular default template, e.g. instructions
    which = params[:which]
    render :partial=>"period_#{which}_default", :layout=>false
  end
  
  def test_period_template
    #-- Show a template with the liquid macros filled in
    which = params[:which]
    @dialog_id = params[:id]
    @dialog = Dialog.find_by_id(@dialog_id)
    @period_id = params[:period_id]
    @period = Period.find_by_id(@period_id)
    @group_id = session[:group_id].to_i
    @group = Group.find_by_id(@group_id) if @group_id > 0
    @dialog_group = DialogGroup.where("group_id=#{@group_id} and dialog_id=#{@dialog_id}").first
    if @dialog.shortname.to_s != "" and @group and @group.shortname.to_s != ""
  		@domain =  "#{@dialog.shortname}.#{@group.shortname}.#{ROOTDOMAIN}"
  	elsif @dialog.shortname.to_s != ""
  		@domain =  "#{@dialog.shortname}.#{ROOTDOMAIN}"
  	else
  		@domain = "#{BASEDOMAIN}"
  	end
    @logo = "https://#{BASEDOMAIN}#{@dialog.logo.url}" if @dialog.logo.exists?
    @participant = current_participant
    @email = @participant.email
    @name = @participant.name
    
    cdata = {}
    cdata['group'] = @group if @group
    cdata['period'] = @period if @period
    cdata['dialog'] = @dialog if @dialog
    cdata['group_logo'] = "https://#{BASEDOMAIN}#{@group.logo.url}" if @group.logo.exists?
    cdata['dialog_logo'] = "https://#{BASEDOMAIN}#{@dialog.logo.url}" if @dialog.logo.exists?
    cdata['dialog_group'] = @dialog_group if @dialog_group
    cdata['participant'] = @participant
    cdata['recipient'] = @participant
    cdata['domain'] = @domain
    cdata['password'] = '[#@$#$%$^]'
    cdata['confirmlink'] = "https://#{@domain}/front/confirm?code=#{@participant.confirmation_token}&group_id=#{@group_id}"
    cdata['logo'] = @logo if @logo
      
    if @period.send("#{which}").to_s != ""
      template_content = render_to_string(:text=>@period.send("#{which}"),:layout=>false)
    else
      template_content = render_to_string(:partial=>"period_#{which}_default",:layout=>false)
    end      
    template = Liquid::Template.parse(template_content)
    render inline: template.render(cdata), layout: 'front'
  end
  
  def set_show_previous
    # Record the current state of showing previous results in a cookie
    if params[:show_previous].to_i == 1
      @showing_previous = true
    else
      @showing_previous = false
    end
    session[:showing_previous] = @showing_previous
    render plain: (@showing_previous ? "1" : "0")
  end
  
  protected 
  
  def dvalidate
    flash[:alert] = ''
    if params[:dialog][:name].to_s == ''
      flash[:alert] += "The discussion needs a name<br/>"
    elsif params[:dialog][:shortname].to_s == ''
      flash[:alert] += "The discussion needs a short code, used for example in e-mail [subject] lines<br/>"
    else
      #-- Check if the shortname is unique
      xshortname = params[:dialog][:shortname]
      xdialog = Dialog.where("shortname='#{xshortname}' and id!=#{@dialog.id.to_i}").first
      if xdialog
        flash[:alert] += "There is already another discussion with the prefix \"#{xshortname}\"<br/>"
      else  
        xgroup = Group.where("shortname='#{xshortname}'").first
        if xgroup
          flash[:alert] += "There is already a group with the prefix \"#{xshortname}\"<br/>"
        end  
      end  
    end
    if params[:dialog][:openness].to_s == ''
      flash[:alert] += "Please choose a membership setting<br/>"
    end
    if params[:dialog][:visibility].to_s == ''
      flash[:alert] += "Please set the visibility<br/>"
    end
    logger.info("dialogs_controller#dvalidate failed: #{flash[:alert]}") if flash[:alert] != ''
    flash[:alert] == ''
  end

  def update_prefix
    #-- Update the current dialog, and the prefix and base url
    return if not @dialog
    before_group_id = session[:group_id] if session[:group_id]
    before_dialog_id = session[:dialog_id] if session[:dialog_id]
    session[:dialog_id] = @dialog.id
    session[:dialog_name] = @dialog.name
    session[:dialog_prefix] = @dialog.shortname
    if session[:dialog_prefix].to_s != '' and session[:group_prefix].to_s != ''
      session[:cur_prefix] = session[:dialog_prefix] + '.' + session[:group_prefix]
    elsif session[:group_prefix].to_s != ''
      session[:cur_prefix] = session[:group_prefix]
    elsif session[:dialog_prefix].to_s != ''
      session[:cur_prefix] = session[:dialog_prefix]
    end
    if session[:cur_prefix] != ''
      session[:cur_baseurl] = "//" + session[:cur_prefix] + "." + ROOTDOMAIN    
    else
      session[:cur_baseurl] = "//" + BASEDOMAIN    
    end
    if participant_signed_in? and ( session[:group_id] != before_group_id or session[:dialog_id] != before_dialog_id )
       current_participant.last_group_id = session[:group_id] if session[:group_id]
       current_participant.last_dialog_id = session[:dialog_id] if session[:dialog_id]
       current_participant.save
    end
  end
  
  def redirect_subdom
    #-- If we're not using the right subdomain, redirect
    #if request.get? and session[:cur_prefix] != '' and Rails.env == 'production' and (request.host == BASEDOMAIN or request.host == ROOTDOMAIN)
    #  host_should_be = "#{session[:cur_prefix]}.#{ROOTDOMAIN}"
    #  if request.host != host_should_be
    #    logger.info("dialogs#redirect_subdom cur_prefix:#{session[:cur_prefix]}<< redirecting from #{request.host} to #{host_should_be}")
    #    redirect_to "http://#{host_should_be}#{request.fullpath}"
    #  end
    #end
  end
  
  def show_name_in_result(item,dialog,period)
    #-- The participants name in results. Don't show it if the settings say so
		if dialog.current_period.to_i > 0 and item.period_id==dialog.current_period and not dialog.settings_with_period["names_visible_voting"]
		  #-- Item is in the current period and it says to now show it
			"[name withheld during decision period]"
		elsif period and not period.names_visible_general
			"[name withheld for this decision period]"
		elsif not dialog.names_visible_general
			"[name withheld for this discussion]"
		else
			"<a href=\"/participant/#{item.id}/profile\">" + ( item.participant ? item.participant.name : item.posted_by ) + "</a>"
		end
  end
  
  def dialog_params
    params.require(:dialog).permit(:logo, :name, :shortname, :description, :shortdesc, :instructions, :visibility, :openness, :moderation, :publishing, :max_voting_distribution, :max_characters, :max_words, :max_mess_length, :front_template, :member_template, :invite_template, :import_template, :signup_template, :confirm_template, :confirm_email_template, :confirm_welcome_template, :list_template, :metamap_vote_own, :default_message, :required_message, :required_subject, :alt_logins, :max_messages, :new_message_title, :allow_replies, :required_meta, :value_calc, :profiles_visible, :names_visible_voting, :names_visible_general, :in_voting_round, :posting_open, :voting_open, :current_period, :twitter_hash_tag, :default_datetype, :default_datefixed, :default_datefrom)
  end
  
  def period_params
    params.require(:period).permit(:name,:shortname,:description,:shortdesc,:instructions,:max_characters,:max_words,:metamap_vote_own,:default_message,:required_message,:required_subject,:max_messages,:new_message_title,:allow_replies,:required_meta,:value_calc,:profiles_visible,:names_visible_voting,:names_visible_general,:posting_open,:voting_open,:sort_metamap_id,:sort_order,:crosstalk,:period_number,:startdate,:endposting,:endrating)
  end

end
