require 'will_paginate/array'

class ItemsController < ApplicationController

  layout "front"
  before_filter :authenticate_user_from_token!, :except=>[:pubgallery]
  before_filter :authenticate_participant!, :except=>[:pubgallery,:view]

  def index
    list  
  end  

  def list
    #-- Return the items to show on the page
    @from = params[:from] || ''
    @ratings = (params[:ratings].to_i == 1)
    @sortby = params[:sortby] || "items.id desc"
    @perscr = params[:perscr].to_i || 25
    @threads = params[:threads] || 'flat'
    @limit_group_id = (params[:limit_group_id] || 0).to_i
    @dialog_id = (params[:dialog_id] || 0).to_i
    @period_id = (params[:period_id] || 0).to_i
    @exp_item_id = (params[:exp_item_id] || 0).to_i
    @tag = params[:tag].to_s
    @subgroup = params[:subgroup].to_s
    @posted_by_country_code = (params[:posted_by_country_code] || '').to_s
    @posted_by_admin1uniq = (params[:posted_by_admin1uniq] || '').to_s
    @posted_by_metro_area_id = (params[:posted_by_metro_area_id] || 0).to_i
    @posted_by_indigenous = (params[:posted_by_indigenous].to_i == 1)
    @posted_by_other_minority = (params[:posted_by_other_minority].to_i == 1)
    @posted_by_veteran = (params[:posted_by_veteran].to_i == 1)
    @posted_by_interfaith = (params[:posted_by_interfaith].to_i == 1)
    @rated_by_country_code = (params[:rated_by_country_code] || '').to_s
    @rated_by_admin1uniq = (params[:rated_by_admin1uniq] || '').to_s
    @rated_by_metro_area_id = (params[:rated_by_metro_area_id] || 0).to_i
    @rated_by_indigenous = (params[:rated_by_indigenous].to_i == 1)
    @rated_by_other_minority = (params[:rated_by_other_minority].to_i == 1)
    @rated_by_veteran = (params[:rated_by_veteran].to_i == 1)
    @rated_by_interfaith = (params[:rated_by_interfaith].to_i == 1)
    @want_crosstalk = params[:want_crosstalk].to_s
    session[:want_crosstalk] = @want_crosstalk if @want_crosstalk != ''
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    @perscr = 25 if @perscr < 1    
    @dialog = Dialog.find_by_id(@dialog_id) if @dialog_id > 0
    if @period_id > 0
      @period = Period.find_by_id(@period_id)
    elsif @dialog and @dialog.active_period
      @period = @dialog.active_period
      #@period_id = @dialog.active_period.id
    end    
    @limit_group = Group.find_by_id(@limit_group_id) if @limit_group_id > 0
    @has_subgroups = (@limit_group and @limit_group.group_subtags.length > 1)
    
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@limit_group.id,current_participant.id).first if @limit_group
    @is_member = @group_participant ? true : false
    @is_moderator = (@group_participant and @group_participant.moderator) or current_participant.sysadmin
    
    if @threads == 'flat' or @threads == 'tree' or @threads == 'root'
      @rootonly = true
    end

    if @from == 'wall'
      @posted_by = ( params[:id] || current_participant.id ).to_i
      @participant = Participant.find(@posted_by)
    else
      @posted_by = 0  
    end   

    @show_meta = false
    if @sortby == 'default'
      sortby = 'items.id desc'
    elsif @sortby[0,5] == 'meta:' and @from == 'dialog'
      metamap_id = @sortby[5,10].to_i
      sortby = "metamap_nodes.name"
      #@items = @items.where("metamap_nodes.metamap_id=#{metamap_id}")
      #@show_meta = true
    elsif @sortby[0,5] == 'meta:'
      sortby = 'items.id desc'
      @sortby = sortby
    else
      sortby = @sortby
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
            
    if true
      #-- Get the records, while adding up the stats on the fly
      
      @items, @itemsproc, @extras = Item.list_and_results(@limit_group,@dialog_id,@period_id,@posted_by,@posted_meta,@rated_meta,@rootonly,@sortby,current_participant,true,0,'','',@posted_by_country_code,@posted_by_admin1uniq,@posted_by_metro_area_id,@rated_by_country_code,@rated_by_admin1uniq,@rated_by_metro_area_id,@tag,@subgroup,false,'','',@want_crosstalk,@posted_by_indigenous,@posted_by_other_minority,@posted_by_veteran,@posted_by_interfaith,@rated_by_indigenous,@rated_by_other_minority,@rated_by_veteran,@rated_by_interfaith)
      
      #logger.info("items_controller#list @items: #{@items.inspect}")
      
    else
      # old way
        
      @items = Item.where(nil)
      #@items = @items.tagged_with(params[:tags]) if params[:tags].to_s != ''
      #@items = @items.where(:group_id => params[:group_id]) if params[:group_id].to_i > 0
      #@items = @items.includes([:group,:participant,:ratings,:item_rating_summary]).where("ratings.participant_id=#{current_participant.id} or ratings.participant_id is null")
      if @group_id > 0
        @items = @items.where("items.group_id = ?", @group_id)    
      end
      if @dialog_id > 0
        @items = @items.where("items.dialog_id = ?", @dialog_id)    
      elsif @dialog_id < 0
        #-- This is when we particularly don't want any discussion messages
        @items = @items.where("items.dialog_id=0 or items.dialog_id is null")  
      end
      if @period_id > 0
        @items = @items.where("items.period_id = ?", @period_id)    
      end
      #@threads = 'flat' if @threads == ''
      if @threads == 'flat' or @threads == 'tree' or @threads == 'root'
        #- Show original message followed by all replies in a flat list
        @items = @items.where("is_first_in_thread=1")
      end
    
      if @from == 'wall'
        @participant_id = ( params[:id] || current_participant.id ).to_i
        @participant = Participant.find(@participant_id)
        @items = @items.where(:posted_by => @participant_id)
      elsif @from == 'forum' and @group_id == 0 and @dialog_id == 0
        @items = @items.where(:posted_to_forum => true)  
      end   

      @items = @items.includes([:dialog,:group,:period,{:participant=>{:metamap_node_participants=>:metamap_node}},:item_rating_summary])
      @items = @items.joins("left join ratings on (ratings.item_id=items.id and ratings.participant_id=#{current_participant.id})")
      @items = @items.select("items.*,ratings.participant_id as hasrating,ratings.approval as rateapproval,ratings.interest as rateinterest,'' as explanation")

      if @dialog_id > 0
        #-- For a dialog we might need to filter by metamap for poster and/or rater
        @metamaps = Metamap.joins(:dialogs).where("dialogs.id=#{@dialog_id}")
        for metamap in @metamaps
          if params["posted_by_metamap_#{metamap.id}"].to_i != 0
            posted_by_metamap_node_id = params["posted_by_metamap_#{metamap.id}"].to_i
            #logger.info("items#list Posted by metamap #{metamap.id}: #{posted_by_metamap_node_id}")
            @items = @items.joins("inner join metamap_node_participants p_mnp_#{metamap.id} on (p_mnp_#{metamap.id}.participant_id=items.posted_by and p_mnp_#{metamap.id}.metamap_id=#{metamap.id} and p_mnp_#{metamap.id}.metamap_node_id=#{posted_by_metamap_node_id})")
            #@items = @items.where("p_mnp_#{metamap.id}.participant_id=#{current_participant.id} and p_mnp_#{metamap.id}.metamap_id=#{metamap.id} and p_mnp_#{metamap.id}.metamap_node_id=#{posted_by_metamap_node_id}")
          end
          if params["rated_by_metamap_#{metamap.id}"].to_i != 0
            rated_by_metamap_node_id = params["rated_by_metamap_#{metamap.id}"].to_i
            #@items = @items.joins("join ratings r_#{metamap_id} on (items.id=ratings.item_id)")
            @items = @items.where("(select count(*) from ratings r_#{metamap.id} inner join participants r_p_#{metamap.id} on (r_#{metamap.id}.participant_id=r_p_#{metamap.id}.id) inner join metamap_node_participants r_mnp_#{metamap.id} on (r_mnp_#{metamap.id}.participant_id=r_p_#{metamap.id}.id and r_mnp_#{metamap.id}.metamap_node_id=#{rated_by_metamap_node_id}) where r_#{metamap.id}.item_id=items.id)>0")
          end
        end
      end

    end

    
    #@show_extra = @items.to_sql
    #logger.info("items#list SQL: #{@items.to_sql}")
    
    #if @sortby == 'default'
    #  @dialog = Dialog.find_by_id(@dialog_id)
    #  @items = Item.custom_item_sort(@items, @page, @perscr, current_participant.id, @dialog).paginate :page=>@page, :per_page => @perscr
    #else
    #  @items = @items.order(sortby)
    #  @items = @items.paginate :page=>@page, :per_page => @perscr   
    #end
    
    @items = @items.paginate :page=>@page, :per_page => @perscr  

    if participant_signed_in?
      current_participant.forum_settings = {'sortby'=>sortby,'perscr'=>@perscr,'threads'=>@threads,'group_id'=>@group_id,'dialog_id'=>@dialog_id}
      current_participant.save
    end  
    
    #-- Try to figure out if the user is allowed to post. Mainly to know which message to show them if there are no messages.
    @can_post = false
    if @from == 'dialog'      
      if @dialog.current_period.to_i > 0
        @previous_messages_period = Item.where("posted_by=? and dialog_id=? and period_id=? and (reply_to is null or reply_to=0)",current_participant.id,@dialog.id,@dialog.current_period.to_i).count      
      else
        @previous_messages_period = 0
      end  
      @previous_messages = Item.where("posted_by=? and dialog_id=? and (reply_to is null or reply_to=0)",current_participant.id,@dialog.id).count
      if session[:group_is_member] and ((@dialog.current_period.to_i > 0 and (@dialog.active_period.max_messages.to_i == 0 or @previous_messages_period < @dialog.active_period.max_messages.to_i)) or (@dialog.current_period.to_i == 0 and (@dialog.max_messages.to_i == 0 or @previous_messages < @dialog.max_messages.to_i))) and @dialog.settings_with_period["posting_open"]
        @can_post = true
      end
    elsif @from == 'group'
      if @is_member
        @can_post = true        
      end
    elsif @from == 'wall'
      if @posted_by == current_participant.id
        @can_post = true
      end
    end
    
    if @ratings
      render :partial=>'ratings', :layout=>false       
    else  
      render :partial=>'list', :layout=>false 
    end   
  end  
  
  def list_comments_simple
    #-- Comments for a particular item, for the simple view. Probably called after we added a comment
    @item_id = params[:id].to_i
    item = Item.find_by_id(@item_id)
    
    #@itemsproc   NB !!!!!!!!!!!!!!!!!!!! Where does that come from?
    #-- We basically need the same kind of stuff as if we doing a listing, so that we can get an @itemsproc
    @items, @itemsproc, @extras = Item.list_and_results(nil,item.dialog,item.period_id,0,{},{},true,'default',current_participant)

    #logger.info("items#list_comments_simple @item_id:#{@item_id} item.id:#{item.id} @itemsproc:#{@itemsproc.length} @itemsproc[@item_id]:#{@itemsproc[@item_id].class}")  
    @replies = @itemsproc[item.id]['replies']
  
    
    render :partial=>'item_dsimple_comments', :locals => { :item => item, :replies => @replies, :odd_or_even => 1, :from => 'dsimple'}, :layout=>false       
  end  
  
  def new
    #-- screen for a new item, either new thread or a reply
    @from = params[:from] || ''
    @reply_to = params[:reply_to].to_i
    @item = Item.new(:media_type=>'text',:link=>'http://',:reply_to=>@reply_to)
    @item.geo_level = params[:geo_level] if params[:geo_level].to_s != ''
    @items_length = params[:items_length].to_i
    @subgroup = params[:subgroup].to_s
    if params[:group_id].to_i > 0
      @item.group_id = params[:group_id] 
    else
      @item.group_id = 0      
    end
    if params[:dialog_id].to_i > 0
      @dialog_id = params[:dialog_id].to_i
      @item.group_id = session[:group_id].to_i if @item.group_id == 0
    else
      @dialog_id = 0      
    end
    if @dialog_id > 0
      @dialog = Dialog.find_by_id(@dialog_id)
      @dialog_name = (@dialog ? @dialog.name : '???')
      @item.period_id = @dialog.current_period if @dialog
    end  
    @item.dialog_id = @dialog_id
    #@max_characters = @dialog ? @dialog.max_characters : 0    
    #@max_words = @dialog ? @dialog.max_words : 0
    
    @max_characters = @dialog ? @dialog.settings_with_period["max_characters"] : 0
    @max_words = @dialog ? @dialog.settings_with_period["max_words"] : 0
    
    if current_participant.status != 'active'
      #-- Make sure this is an active member
      render :text=>"<p>Your membership is not active</p>", :layout=>false
      return
    end    
    
    if @item.reply_to.to_i > 0
      @item.is_first_in_thread = false 
      @olditem = Item.find_by_id(@item.reply_to)
      if @olditem
        @item.first_in_thread = @olditem.first_in_thread
        if @olditem.subject.to_s != '' and @olditem.subject[0,3] != 'Re:' and @olditem.subject[0,3] != 're:'
          #@item.subject = "Re: #{@olditem.subject}"[0,48]  
          @item.subject = "Re: #{@olditem.subject}"  
        elsif @olditem.subject != ''
          @item.subject = @olditem.subject 
        end
        @item.group_id = @olditem.group_id if @item.group_id.to_i == 0 and @olditem.group_id.to_i > 0
        @item.dialog_id = @olditem.dialog_id if @olditem.dialog_id.to_i > 0
        if @item.dialog_id.to_i > 0
          @dialog = Dialog.find_by_id(@item.dialog_id)
          @dialog_name = (@dialog ? @dialog.name : '???')
          @item.period_id = @dialog.current_period if @dialog
        end  
        @item.subgroup_list = @olditem.subgroup_list if @olditem.subgroup_list.to_s != ''
      end
    else
      if @dialog and @dialog.settings_with_period["default_message"].to_s != ''
        @item.html_content = @dialog.settings_with_period["default_message"]
      end 
      #@item.subgroup_list = @subgroup if @subgroup.to_s != ''   
      @subgroup_add = @subgroup
    end   

    @groupsin = GroupParticipant.where("participant_id=#{current_participant.id}").includes(:group)       
    @dialogsin = DialogParticipant.where("participant_id=#{current_participant.id}").includes(:dialog)  
    @dialoggroupsin = []
    if @dialog
      #-- The user might be a member of several of the groups participating in the current dialog, if any
      for group1 in @dialog.groups
        for group2 in @groupsin
          if group2.group and group2.group.id == group1.id
            @dialoggroupsin << group1
          end
        end
      end
    end   

    #-- Don't allow sending to group or dialog one isn't a member of
    if @item.group_id > 0
      ingroup = false
      for gp in @groupsin
        ingroup = true if gp.group and gp.group_id == @item.group_id and gp.active and gp.status == 'active'
      end 
      if not ingroup
        @item.group_id = 0 
        if @item.reply_to.to_i == 0
          render :text=>"<p>You're not a member of that group</p>", :layout=>false
          return
        end
      end
    end
    #if @item.dialog_id > 0
    #  indialog = false
    #  for dp in @dialogsin
    #    indialog = true if dp.dialog_id == @item.dialog_id
    #  end
    #  @item.dialog_id = 0 if not indialog
    #end

    if @item.group_id > 0
      @group = Group.find_by_id(@item.group_id)
      @send_to = "G#{@item.group_id}"
      @send_to_name = 'Group: ' + (@group ? @group.name : '???')
    #elsif @item.dialog_id > 0
    #  @dialog = Dialog.find_by_id(@item.dialog_id)
    #  @send_to = "D#{@item.dialog_id}"
    #  @send_to_name = 'Dialog: ' + (@dialog ? @dialog.name : '???')
    #  @dialog_name = (@dialog ? @dialog.name : '???')
    elsif current_participant.item_to_forum
      @send_to = 'all'  
      @send_to_name = '*everybody forum / my wall*'
    else
      @send_to = 'wall'
      @send_to_name = '*my wall*'
    end    
    
    #-- Check if they're not allowed to post a new root message, based on dialog/period settings, etc.
    if @dialog and @item.reply_to.to_i == 0
      if @dialog.active_period and @dialog.active_period.max_messages.to_i > 0
        @previous_messages_period = Item.where("posted_by=? and dialog_id=? and period_id=? and (reply_to is null or reply_to=0)",current_participant.id,@dialog.id,@dialog.current_period.to_i).count      
        if @previous_messages_period >= @dialog.active_period.max_messages.to_i
          render :text=>"<p>You've already reached your maximum number of threads for this period</p>", :layout=>false
          return
        end
      end  
      if @dialog.max_messages.to_i > 0
        @previous_messages = Item.where("posted_by=? and dialog_id=? and (reply_to is null or reply_to=0)",current_participant.id,@dialog.id).count
        if @previous_messages >= @dialog.max_messages.to_i
          render :text=>"<p>You've already reached your maximum number of threads for this discussion</p>", :layout=>false
          return
        end
      end
    end
    
    render :partial=>'edit', :layout=>false
  end  

  def edit
    #-- screen for a editing a message
    @from = params[:from] || ''
    @item_id = params[:id]
    @item = Item.find(@item_id)
    @items_length = params[:items_length].to_i

    prepare_edit

    if @item.group_id > 0
      @send_to = "G#{@item.group_id}"
      @send_to_name = 'Group: ' + (@group ? @group.name : '???')
    elsif @item.dialog_id > 0
      @send_to = "D#{@item.dialog_id}"
      @send_to_name = 'Dialog: ' + (@dialog ? @dialog.name : '???')
    elsif @item.posted_to_forum
      @send_to = 'all'  
      @send_to_name = '*everybody forum / my wall*'
    else
      @send_to = 'wall'
      @send_to_name = '*my wall*'
    end   
    render :partial=>'edit', :layout=>false
  end  
  
  def prepare_edit
    #-- Get a few things ready for editing or adding an item
    @group = Group.find_by_id(@item.group_id) if @item.group_id > 0
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).first if @group
    @is_member = @group_participant ? true : false
    @is_moderator = ((@group_participant and @group_participant.moderator) or current_participant.sysadmin)
    if @item.dialog_id.to_i > 0
      @dialog_id = @item.dialog_id
      @dialog = Dialog.find_by_id(@item.dialog_id)
      @dialog_name = (@dialog ? @dialog.name : '???')
    end  
    @groupsin = GroupParticipant.where("participant_id=#{current_participant.id}").includes(:group)       
    @dialogsin = DialogParticipant.where("participant_id=#{current_participant.id}").includes(:dialog) 
    @dialoggroupsin = []
    if @dialog
      #-- The user might be a member of several of the groups participating in the current dialog, if any
      for group1 in @dialog.groups
        for group2 in @groupsin
          if group2.group && group2.group.id == group1.id
            @dialoggroupsin << group1
          end
        end
      end
    end   
    @max_characters = @dialog ? @dialog.settings_with_period["max_characters"] : 0
    @max_words = @dialog ? @dialog.settings_with_period["max_words"] : 0
  end
    
  def create
    @from = params[:from] || ''
    @item = Item.new(item_params)
    @item.link = '' if @item.link == 'http://'
    @item.item_type = 'message'
    @item.posted_by = current_participant.id
    @item.geo_level = params[:geo_level] if params[:geo_level]

    if current_participant.status != 'active'
      #-- Make sure this is an active member
      results = {'error'=>true,'message'=>"Your membership is not active",'item_id'=>0}        
      render :json=>results, :layout=>false
      return
    end    
    
    if @item.reply_to.to_i > 0
      @item.is_first_in_thread = false 
      @olditem = Item.find_by_id(@item.reply_to)
      if @olditem
        if @olditem.first_in_thread.to_i > 0
          @item.first_in_thread = @olditem.first_in_thread
        else
          @item.first_in_thread = @item.reply_to
        end 
        if @olditem.first_in_thread_group_id.to_i > 0
          @item.first_in_thread_group_id = @olditem.first_in_thread_group_id
        else  
          @item.first_in_thread_group_id = @olditem.group_id
        end  
        @item.subgroup_list = @olditem.subgroup_list if @olditem.subgroup_list.to_s != ''
        if current_participant.id != @olditem.posted_by
          @olditem.edit_locked = true
          @olditem.save
        end
      end
    else
      @item.is_first_in_thread = true 
      @item.first_in_thread_group_id = @item.group_id
    end    
    logger.info("items#create by #{@item.posted_by}")

    if not itemvalidate
      logger.info("items#create by #{@item.posted_by}: failing validation: #{@xmessage}")
      flash.now[:alert] = @xmessage
    end
    logger.info("items#create item is validated")
    
    itemprocess
    logger.info("items#create item has been processed")
    
    if @item.dialog_id > 0 and @dialog
      #-- Various controls set by either a discussion or by a focus group in a discussion
      # open for posting?
      if not @dialog.settings_with_period["posting_open"] and @item.reply_to.to_i == 0
        flash.now[:alert] = "Sorry, this discussion is not open for new messages"
      end      
      #if @item.reply_to.to_i == 0 and @dialog.settings_with_period["max_messages"].to_i > 0
      #  max_messages = @dialog.settings_with_period["max_messages"].to_i
      #  previous_messages = Item.where("posted_by=? and dialog_id=? and reply_to is null",current_participant.id,@dialog.id).count
      #  if previous_messages >= max_messages
      #    flash.now[:alert] = "Sorry, you can only post #{max_messages} message#{max_messages > 1 ? 's' : ''} here"
      #  end
      #  if @item.period_id > 0 and @dialog.active_period and @dialog.active_period.max_messages.to_i > 0
      #    previous_messages_period = Item.where("posted_by=? and dialog_id=? and period_id=? and (reply_to is null or reply_to=0)",current_participant.id,@dialog.id,@dialog.current_period.to_i).count      
      #    if previous_messages_period >= @dialog.active_period.max_messages.to_i
      #      flash.now[:alert] = "Sorry, you can only post #{@dialog.active_period.max_messages} message#{max_messages > 1 ? 's' : ''} here"
      #    end
      #  end
      #end
      plain_content = view_context.strip_tags(@item.html_content.to_s).strip
      if @item.reply_to.to_i > 0 and not @dialog.settings_with_period["allow_replies"]
        flash.now[:alert] = 'Sorry, replies are not permitted here'
      elsif @dialog.settings_with_period["required_subject"] and @item.subject.to_s.strip == ""
        flash.now[:alert] = "A subject is required"
      elsif @item.is_first_in_thread and @dialog.settings_with_period["max_characters"].to_i > 0 and 1.0 * plain_content.length > @dialog.settings_with_period["max_characters"] * 1.05
        flash.now[:alert] = "That's too many characters"
      elsif @item.is_first_in_thread and @dialog.settings_with_period["max_words"].to_i > 0 and 1.0 * plain_content.scan(/(\w|-)+/).size > @dialog.settings_with_period["max_words"] * 1.05
        flash.now[:alert] = "That's too many words"
      end
    end
        
    if flash[:alert] or flash.now[:alert]
      prepare_edit
      render :partial=>'edit', :layout=>false
      return
    
    elsif @item.save
      if @item.is_first_in_thread
        @item.first_in_thread = @item.id    
        @item.save    
      end  
      #if current_participant.twitter_post and current_participant.twitter_username.to_s !='' and current_participant.twitter_oauth_token.to_s != ''
      #  #-- Post to Twitter
      #  begin
      #    Twitter.configure do |config|
      #      config.consumer_key = TWITTER_CONSUMER_KEY
      #      config.consumer_secret = TWITTER_CONSUMER_SECRET
      #      config.oauth_token = current_participant.twitter_oauth_token
      #      config.oauth_token_secret = current_participant.twitter_oauth_secret
      #    end
      #    Twitter.update(@item.short_content)
      #  rescue
      #    logger.info("items#create problem posting to twitter")
      #  end  
      #end
      ##-- E-mail to everybody who's asked for it
      #@item.emailit
      
      current_participant.update_attribute(:has_participated,true) if not current_participant.has_participated
      #render :text=>'Item was successfully created.', :layout=>false
      results = {'error'=>false,'message'=>"Item was successfully created.",'item_id'=>@item.id}        
      render :json=>results, :layout=>false
      
    end  
  end  
  
  def update
    @from = params[:from] || ''
    @item = Item.find(params[:id])
    @item.link = '' if @item.link == 'http://'
    
    @item.assign_attributes(item_params)
    
    @item.censored = false if not params[:item][:censored] or params[:item][:censored].to_i == 0

    if not itemvalidate
      #render :text=>@xmessage, :layout=>false
      #results = {'error'=>true,'message'=>@xmessage,'item_id'=>@item.id}
      #render :json=>results, :layout=>false
      #return
      flash.now[:alert] = @xmessage
    end
    if flash[:alert] or flash.now[:alert]
      prepare_edit
      render :partial=>'edit', :layout=>false
      return
    end
    #if @item.update_attributes(params[:item])
      itemprocess
      @item.save
      #showmess = (@error_message.to_s != '') ? @error_message : "Item was successfully updated."
      if @error_message.to_s != ''
        results = {'error'=>true,'message'=>@error_message,'item_id'=>@item.id}
      else
        results = {'error'=>false,'message'=>"Item was successfully updated.",'item_id'=>@item.id}        
      end  
      render :json=>results, :layout=>false
      #render :text=>showmess, :layout=>false
    #end   
  end  
  
  def destroy
    @from = params[:from] || ''
    @item = Item.find(params[:id])
    if Item.where("is_first_in_thread=0 and first_in_thread=#{@item.id}").count > 0
      #-- It has replies, we can't delete
      render :text => "Can't delete this item. It has replies", :layout => false
      return
    end  
    @item.destroy
    render :text => "The item has been deleted", :layout => false    
  end  
  
  def view
    #-- Show an individual post
    @from = params[:from] || 'individual'
    @item_id = params[:id]
    @item = Item.includes([:dialog,:group,{:participant=>{:metamap_node_participants=>:metamap_node}},:item_rating_summary])
    
    @item = @item.joins("left join ratings r_has on (r_has.item_id=items.id and r_has.participant_id=#{current_participant.id})") if participant_signed_in?
    @item = @item.select("items.*,r_has.participant_id as hasrating,r_has.approval as rateapproval,r_has.interest as rateinterest,'' as explanation") if participant_signed_in?    
    @item = @item.find_by_id(@item_id)
    
    @item.voting_ok(participant_signed_in? ? current_participant.id : 0)

    @group_id,@dialog_id = get_group_dialog_from_subdomain

    @group_id = @item.group_id
    if @group_id.to_i > 0
      @group = Group.includes(:owner_participant).find(@group_id)
      if participant_signed_in?
        @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).first
        @is_member = @group_participant ? true : false
        @is_moderator = ((@group_participant and @group_participant.moderator) or current_participant.sysadmin)
      else
        @is_member = false
        @is_moderator = false
      end
      #@from = "group"
      session[:group_is_member] = @is_member
      session[:group_name] = @group.name
      session[:group_prefix] = @group.shortname
    end
    session[:group_id] = @group_id

    @dialog_id = @item.dialog_id
    if @dialog_id.to_i > 0
      @dialog = Dialog.includes(:groups).find_by_id(@dialog_id)   
      @groups = @dialog.groups if @dialog and @dialog.groups
      @periods = @dialog.periods if @dialog and @dialog.periods
      if participant_signed_in?
        @groupsin = GroupParticipant.where("participant_id=#{current_participant.id}").includes(:group)
        dialogadmin = DialogAdmin.where("dialog_id=? and participant_id=?",@dialog_id, current_participant.id)
        @is_admin = (dialogadmin.length > 0)
        @previous_messages = Item.where("posted_by=? and dialog_id=? and (reply_to is null or reply_to=0)",current_participant.id,@dialog_id).count
      else
        @is_admin = false
        @previous_messages = []
      end
      #@from = "dialog"
    end
    session[:dialog_id] = @dialog_id
    
    if @dialog_id.to_i > 0 and @group_id.to_i > 0 and participant_signed_in? and not @is_member
      #-- If the reader isn't a member of the group the message is posted under, see if he's a member of another group in the discussion
      for group in @dialog.groups
        group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group_id,current_participant.id).first
        if group_participant and group_participant.group
          @group_id = group.id
          @group = group
          @is_member = true
          session[:group_id] = @group_id
          session[:group_is_member] = @is_member
          break
        end
      end
    end
    
    @period_id = 0
    @posted_by = 0
    @posted_meta={}
    @rated_meta={}
    @rootonly = false
    @sortby = "items.id desc"
    @posted_by_country_code = ''
    @posted_by_admin1uniq = ''
    @posted_by_metro_area_id = 0
    @rated_by_country_code = ''
    @rated_by_admin1uniq = ''
    @rated_by_metro_area_id = 0
    
    #-- Even though we're only showing one item, we still need to get the context, with the ratings, etc.
    if participant_signed_in?
      @items, @itemsproc, @extras = Item.list_and_results(@group,@dialog,@period_id,@posted_by,@posted_meta,@rated_meta,@rootonly,@sortby,current_participant,true,0,'','',@posted_by_country_code,@posted_by_admin1uniq,@posted_by_metro_area_id,@rated_by_country_code,@rated_by_admin1uniq,@rated_by_metro_area_id)
    else
      @items, @itemsproc, @extras = Item.list_and_results(@group,@dialog,@period_id,@posted_by,@posted_meta,@rated_meta,@rootonly,@sortby,0,true,0,'','',@posted_by_country_code,@posted_by_admin1uniq,@posted_by_metro_area_id,@rated_by_country_code,@rated_by_admin1uniq,@rated_by_metro_area_id)
    end

    update_last_url
    #update_prefix

    render :action=>'item'
  end  
  
  def thread
    #-- Show the whole thread, based on an item
    @from = params[:from] || 'thread'
    @item_id = params[:id]
    @exp_item_id = (params[:exp_item_id] || 0).to_i
    @item = Item.includes([:dialog,:group,{:participant=>{:metamap_node_participants=>:metamap_node}},:item_rating_summary]).find(@item_id)
    
    @dialog_id = @item.dialog_id
    if @dialog_id.to_i > 0
      @dialog = Dialog.includes(:groups).find_by_id(@dialog_id)   
      @groups = @dialog.groups if @dialog and @dialog.groups
      @periods = @dialog.periods if @dialog and @dialog.periods
      @groupsin = GroupParticipant.where("participant_id=#{current_participant.id}").includes(:group)
      dialogadmin = DialogAdmin.where("dialog_id=? and participant_id=?",@dialog_id, current_participant.id)
      @is_admin = (dialogadmin.length > 0)
      @previous_messages = Item.where("posted_by=? and dialog_id=? and (reply_to is null or reply_to=0)",current_participant.id,@dialog.id).count
    end
    
    @group_id = @item.group_id
    if @group_id.to_i > 0
      @group = Group.includes(:owner_participant).find(@group_id)
      @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).first
      @is_member = @group_participant ? true : false
      @is_moderator = ((@group_participant and @group_participant.moderator) or current_participant.sysadmin)
    end

    if participant_signed_in? and current_participant.forum_settings
      set = current_participant.forum_settings
    else
      set = {}
    end    

    @first_item_id = @item.first_in_thread
    @first_item = Item.find(@first_item_id )

    @period_id = 0
    @posted_by = 0
    @posted_meta={}
    @rated_meta={}
    @rootonly = false
    @sortby = "items.id desc"
    @posted_by_country_code = ''
    @posted_by_admin1uniq = ''
    @posted_by_metro_area_id = 0
    @rated_by_country_code = ''
    @rated_by_admin1uniq = ''
    @rated_by_metro_area_id = 0
    
    #-- Even though we're only showing one item, we still need to get the context, with the ratings, etc.
    @items, @itemsproc, @extras = Item.list_and_results(@group,@dialog,@period_id,@posted_by,@posted_meta,@rated_meta,@rootonly,@sortby,current_participant,true,0,'','',@posted_by_country_code,@posted_by_admin1uniq,@posted_by_metro_area_id,@rated_by_country_code,@rated_by_admin1uniq,@rated_by_metro_area_id)

    update_last_url
    #update_prefix

    render :action=>'thread'
  end
  
  def rate
    #-- rate an item
    @from = params[:from] || ''
    intapp = params[:intapp]
    item_id = params[:id].to_i
    vote = params[:vote].to_i
    
    item = Item.includes(:dialog,:group).find_by_id(item_id)

    group_id = item.group_id.to_i
    dialog_id = item.dialog_id.to_i
    
    #-- Check if they're allowed to rate it
    if not item.voting_ok(current_participant.id)
      render :text=>'', :layout=>false
      return
    end
    
    #-- See if that user already has rated that item, or create a new rating if they haven't
    #rating = Rating.find_or_initialize_by_item_id_and_participant_id_and_rating_type(item_id,current_participant.id,'AllRatings')
    rating = Rating.where(item_id: item_id, participant_id: current_participant.id, rating_type: 'AllRatings').first_or_initialize
    
    if intapp == 'int'
      rating.interest = vote
    elsif intapp == 'app'
      rating.approval = vote
    end    
    
    rating.save!
    
    #item_rating_summary = ItemRatingSummary.find_or_create_by_item_id(item_id)
    item_rating_summary = ItemRatingSummary.where(item_id: item_id).first_or_create
    if current_participant.id == 6
      item_rating_summary.recalculate(false,item.dialog)      
    else
      item_rating_summary.recalculate(false,item.dialog)
    end
    if (dialog_id > 0 and rating.dialog_id.to_i == 0) or (group_id > 0 and rating.group_id.to_i == 0)
      rating.group_id = group_id
      rating.dialog_id = dialog_id
      if dialog_id > 0
        dialog = Dialog.find_by_id(dialog_id)
        rating.period_id = dialog.current_period if dialog
      end
      rating.save
    end
    
    item.approval = item_rating_summary.app_average
    item.interest = item_rating_summary.int_average
    item.value = item_rating_summary.value
    item.controversy = item_rating_summary.controversy
    item.edit_locked = true if current_participant.id != item.posted_by
    item.save
    
    render :text=>vote, :layout=>false
  end  
  
  def get_summary
    @item_id = params[:id]
    items = Item.where(:id=>@item_id).includes(:item_rating_summary,:dialog)
    @item = items[0]
    @item.item_rating_summary.recalculate(false,@item.dialog)
    render :partial=>"rating_summary", :layout=>false, :locals=>{:item=>@item}
  end
  
  def play
    #-- return the code for an embedded item, so it can be played
    @from = params[:from] || ''
    @item_id = params[:id]
    @item = Item.find(@item_id)
    render :text=>@item.embed_code, :layout=>false
  end  
  
  def pubgallery
    #-- Public gallery
    @group_id = 8
    @items = Item.where("items.group_id=#{@group_id} and items.has_picture=1 and items.media_type='picture'").includes(:participant).order("items.id desc").limit(12)
  end  
  
  def geoslider
    #-- The main screen or the geo slider
  end

  def geoslider_update
    # Getting listings and results tailored to the slider in discussions
    # Variables are:
    # geo_level: city, metro, state, nation, earth
    # group_level: current, my, all groups. 
  
    # indigenous, other minority, veteran, interfaith
  
    show_result = (params[:show_result].to_i == 1)
  
    crit = {}
  
    geo_level = params[:geo_level].to_i
    session[:geo_level] = geo_level
    geo_levels = GEO_LEVELS               # {1 => 'city', 2 => 'metro', 3 => 'state', 4 => 'nation', 5 => 'planet'}    
    crit[:geo_level] = geo_levels[geo_level]
  
    group_level = params[:group_level].to_i
    session[:group_level] = group_level
    group_levels = {1 => 'current', 2 => 'user', 3 => 'all'}
    crit[:group_level] = group_levels[group_level]
  
    crit[:indigenous] = (params[:indigenous].to_i == 1) ? true : false
    crit[:other_minority] = (params[:other_minority].to_i == 1) ? true : false
    crit[:veteran] = (params[:veteran].to_i == 1) ? true : false
    crit[:interfaith] = (params[:interfaith].to_i == 1) ? true : false
  
    crit[:dialog_id] = params[:dialog_id].to_i
    crit[:period_id] = params[:period_id].to_i
    session[:slider_period_id] = crit[:period_id]
    
    crit[:group_id] = session[:group_id].to_i
  
    crit[:gender] = params[:meta_3].to_i
    crit[:age] = params[:meta_5].to_i
    
    @dialog_id = crit[:dialog_id]
    @period_id = crit[:period_id]
    
    @dialog = Dialog.find_by_id(crit[:dialog_id]) if crit[:dialog_id] > 0
    @period = Period.find_by_id(crit[:period_id]) if crit[:period_id] > 0

    @threads = params[:threads]
    if @threads == 'flat' or @threads == 'tree' or @threads == 'root'
      rootonly = true
    else
      rootonly = false
    end

    #-- See how many total posts there are, to be able to do a graphic
    all_posts = Item.where(nil)
    all_posts = all_posts.where(:is_first_in_thread => true) if rootonly
    all_posts = all_posts.where(dialog_id: crit[:dialog_id]) if crit[:dialog_id] > 0
    all_posts = all_posts.where(period_id: crit[:period_id]) if crit[:period_id] > 0
    @num_all_posts = all_posts.count
  
    @title = ""

    @data = {}  
  
    if show_result
      # If we're showing results, then add up results for the required gender and age combinations
      # We will go through the overall items and ratings we have, and put them in those several buckets
      # Then we will add up the results in each of those buckets
    
      ages = MetamapNode.where(metamap_id: 5).order(:sortorder)
      genders = MetamapNode.where(metamap_id: 3).order(:sortorder)
      
      age = crit[:age]
      gender = crit[:gender]
      
      gender_pos = {207=>"Men's",208=>"Women's"}
    
      if age > 0 and gender > 0
        # One particular result
        age_id = age
        age_name = MetamapNode.where(id: age).first.name_as_group
        gender_id = gender
        #gender_name = MetamapNode.where(id: gender).first.name
        gender_name = gender_pos[gender_id]
        name = "#{gender_name} #{age_name}"
        item = nil
        iproc = nil
        
        crit[:age] = age_id
        crit[:gender] = gender_id
        items,ratings,title = Item.get_items(crit,current_participant)
        itemsproc = Item.get_itemsproc(items,ratings,current_participant.id)
        sortby = '*value*'
        items = Item.get_sorted(items,itemsproc,sortby)
        if items.length > 0
          item = items[0]
          iproc = itemsproc[item.id]
        end
        
        @data['all'] = {name: name, item: item, iproc: iproc}
      elsif age == 0 and gender == 0
        # two genders, three ages, and voice of humanity
        # total
        name = "Voice of Humanity-as-One"
        item = nil
        iproc = nil
        
        items,ratings,title = Item.get_items(crit,current_participant)
        itemsproc = Item.get_itemsproc(items,ratings,current_participant.id)
        sortby = '*value*'
        items = Item.get_sorted(items,itemsproc,sortby)
        if items.length > 0
          item = items[0]
          iproc = itemsproc[item.id]
        end
        
        @data['all'] = {name: name, item: item, iproc: iproc}
        for gender_rec in genders
          gender_id = gender_rec.id
          gender_name = gender_rec.name_as_group
          code = "#{gender_id}"
          name = "#{gender_name}"
          if not gender_rec.sumcat
            item = nil
            iproc = nil
            
            crit[:gender] = gender_id
            items,ratings,title = Item.get_items(crit,current_participant)
            itemsproc = Item.get_itemsproc(items,ratings,current_participant.id)
            sortby = '*value*'
            items = Item.get_sorted(items,itemsproc,sortby)
            if items.length > 0
              item = items[0]
              iproc = itemsproc[item.id]
            end
            
            @data[code] = {name: name, item: item, iproc: iproc}
          end
        end
        for age_rec in ages
          age_id = age_rec.id
          age_name = age_rec.name_as_group
          code = "#{age_id}"
          name = "#{age_name}"
          if not age_rec.sumcat
            item = nil
            iproc = nil
            
            crit[:age] = age_id
            items,ratings,title = Item.get_items(crit,current_participant)
            itemsproc = Item.get_itemsproc(items,ratings,current_participant.id)
            sortby = '*value*'
            items = Item.get_sorted(items,itemsproc,sortby)
            if items.length > 0
              item = items[0]
              iproc = itemsproc[item.id]
            end
            
            @data[code] = {name: name, item: item, iproc: iproc}
          end
        end
      
      elsif age > 0 and gender == 0
        # two genders with a particular age
        age_id = age
        age_name = MetamapNode.where(id: age).first.name
        for gender_rec in genders
          gender_id = gender_rec.id
          gender_name = gender_rec.name
          code = "#{age_id}_#{gender_id}"
          name = "#{age_name} #{gender_name}"
          if not gender_rec.sumcat
            item = nil
            iproc = nil
            
            crit[:age] = age_id
            crit[:gender] = gender_id
            items,ratings,title = Item.get_items(crit,current_participant)
            itemsproc = Item.get_itemsproc(items,ratings,current_participant.id)
            sortby = '*value*'
            items = Item.get_sorted(items,itemsproc,sortby)
            if items.length > 0
              item = items[0]
              iproc = itemsproc[item.id]
            end
            
            @data[code] = {name: name, item: item, iproc: iproc}
          end
        end
      
      elsif age == 0 and gender > 0
        # three ages with a particular gender
        gender_id = gender
        gender_name = MetamapNode.where(id: gender).first.name
        for age_rec in ages
          age_id = age_rec.id
          age_name = age_rec.name
          code = "#{age_id}_#{gender_id}"
          name = "#{age_name} #{gender_name}"
          if not age_rec.sumcat
            item = nil
            iproc = nil
            
            crit[:age] = age_id
            crit[:gender] = gender_id
            items,ratings,title = Item.get_items(crit,current_participant)
            itemsproc = Item.get_itemsproc(items,ratings,current_participant.id)
            sortby = '*value*'
            items = Item.get_sorted(items,itemsproc,sortby)
            if items.length > 0
              item = items[0]
              iproc = itemsproc[item.id]
            end
            
            @data[code] = {name: name, item: item, iproc: iproc}
          end
        end
        
      end
    
      render :partial=>'simple_result'
    
    else
          
      items,ratings,@title = Item.get_items(crit,current_participant,rootonly)
    
      # Add up results for those items and those ratings, to show in the item summaries in the listing
      # I.e. add up the number of interest/approval ratings for each item, do regression to the mean, calculate value, etc
      @itemsproc = Item.get_itemsproc(items,ratings,current_participant.id,rootonly)
  
      # Items probably need to be sorted, based on the results we calculated
      #sortby = '*value*'
      @sortby = params[:sortby]
      @items = Item.get_sorted(items,@itemsproc,@sortby,rootonly)
  
      # Listing. Divide into reasonable batches
      @batches = []
      if @items.length > 4
        @showmax = (params[:batch_size] || 4).to_i
        if @items.length < 13
          @numbatches = 2
        elsif @items.length <= 30   
          @numbatches = 3
        elsif @items.length <= 40
          @numbatches = 4  
        else
          @numbatches = 5  
        end
        @batches << 4
        step = @items.length / (@numbatches - 1)
        pos = 4
        (@numbatches-2).times do
          pos += step
          @batches << pos
        end  
        @batches << @items.length    
      else
        @showmax = (params[:batch_size] || @items.length).to_i
      end  

      render :partial => 'geoslider_update'
  
    end

  end
    
  def geoslider_update_old
    #-- Updating the display for the geo slider
    # 5: Planet Earth
    # 4: Nation
    # 4: State/Province
    # 2: Metro region
    # 1: City

    if session[:num_all_posts].to_i == 0
      #-- See how many total posts there are, to be able to do a graphic
      session[:num_all_posts] = Item.where(:is_first_in_thread => true).count
    end
    @num_all_posts = session[:num_all_posts]
    
    geo_level = params[:geo_level].to_i
    geo_levels = GEO_LEVELS               # {1 => 'city', 2 => 'metro', 3 => 'state', 4 => 'nation', 5 => 'planet'}    
    geo_level = geo_levels[geo_level]
    
    group_level = params[:group_level].to_i
    group_levels = {1 => 'current', 2 => 'user', 3 => 'all'}
    group_level = group_levels[group_level]
    
    indigenous = (params[:indigenous].to_i == 1) ? true : false
    other_minority = (params[:other_minority].to_i == 1) ? true : false
    veteran = (params[:veteran].to_i == 1) ? true : false
    interfaith = (params[:interfaith].to_i == 1) ? true : false
    
    @dialog_id = params[:dialog_id].to_i
    @period_id = params[:period_id].to_i
    
    show_result = (params[:show_result].to_i == 1)

    #1 => 'group'

    @group = nil   
    @group_id = 0
    @posted_by_city = ''
    @posted_by_metro_area_id = 0 
    @posted_by_admin1uniq = ''
    @posted_by_country_code = ''
    
    @title = ""
    
    if geo_level == 'city'
      @posted_by_city = current_participant.city
      @title += "City/Town: #{current_participant.city}"
    elsif geo_level == 'metro'
      @posted_by_metro_area_id = current_participant.metro_area_id
      @title += "Metro Region: #{current_participant.metro_area_id} : #{current_participant.metro_area.name}"
    elsif geo_level == 'state'  
      @posted_by_admin1uniq = current_participant.admin1uniq
      @title += "State/Province: #{current_participant.admin1uniq} : #{current_participant.geoadmin1.name}"
    elsif geo_level == 'nation'
      @posted_by_country_code = current_participant.country_code
      @title += "Nation: #{current_participant.country_code} : #{current_participant.geocountry.name}"
    elsif geo_level == 'planet'
      @title += "Planet Earth"  
    elsif geo_level == 'all'
      @title += "All Perspectives"
    end  
    
    if group_level == 'current'
      @group_id = session[:group_id].to_i
      @group = Group.find_by_id(@group_id) if @group_id > 0
      @title += " | Group: #{@group_id} : #{@group.name}"
    elsif group_level == 'user'
      #-- Groups they're a member of
      @group = current_participant.groups_in.collect{|g| g[0]}
      @title += " |  My #{@group.length} groups"
    elsif group_level == 'all' 
      @group = nil
      @title += " | All groups"   
    end
    @limit_group_id = @group_id

    @posted_meta = {}
    if params[:meta_3].to_i > 0
      @posted_meta[3] = params[:meta_3].to_i
    end
    if params[:meta_5].to_i > 0
      @posted_meta[5] = params[:meta_5].to_i
    end
    # Do we do rated also?
    
    
    #@dialog_id = 0
    #@period_id = 0
    
    @posted_by = 0
    #@posted_meta = {}
    @rated_meta = {}
    @rootonly = true
    @tag = ''
    @subgroup = ''
    @sortby = '*value*'
    
    @rated_by_city = ''
    @rated_by_country_code = ''
    @rated_by_admin1uniq = ''
    @rated_by_metro_area_id = 0
    @metabreakdown = show_result
    @withratings = ''
    @want_crosstalk = ''
    
    @posted_by_indigenous = indigenous
    @posted_by_other_minority = other_minority
    @posted_by_veteran = veteran
    @posted_by_interfaith = interfaith
    @rated_by_indigenous = false
    @rated_by_other_minority = false
    @rated_by_veteran = false
    @rated_by_interfaith = false
    
    @items, @itemsproc, @extras = Item.list_and_results(@group,@dialog_id,@period_id,@posted_by,@posted_meta,@rated_meta,@rootonly,@sortby,current_participant,true,0,'','',@posted_by_country_code,@posted_by_admin1uniq,@posted_by_metro_area_id,@rated_by_country_code,@rated_by_admin1uniq,@rated_by_metro_area_id,@tag,@subgroup,@metabreakdown,@withratings,geo_level,@want_crosstalk,@posted_by_indigenous,@posted_by_other_minority,@posted_by_veteran,@posted_by_interfaith,@rated_by_indigenous,@rated_by_other_minority,@rated_by_veteran,@rated_by_interfaith,@posted_by_city,@rated_by_city)
   
    @data = {}
    if show_result
      @data['totals'] = {'items'=>@items, 'itemsproc'=>@itemsproc, 'extras'=>@extras}
      @data['meta'] = @extras['meta']    

      # We have a breakdown by gender (2), by age (3), or both mixed together (6)
      
      @metamaps = Metamap.where(:id=>[3,5])
      
      #-- Check cross results and see if the voice of humanity matches one of them
      @cross_results = cross_results
          
      
    else
      # Listing. Divide into reasonable batches
      @batches = []
      if @items.length > 4
        @showmax = (params[:batch_size] || 4).to_i
        if @items.length < 13
          @numbatches = 2
        elsif @items.length <= 30   
          @numbatches = 3
        elsif @items.length <= 40
          @numbatches = 4  
        else
          @numbatches = 5  
        end
        @batches << 4
        step = @items.length / (@numbatches - 1)
        pos = 4
        (@numbatches-2).times do
          pos += step
          @batches << pos
        end  
        @batches << @items.length    
      else
        @showmax = (params[:batch_size] || @items.length).to_i
      end  
    end

    if show_result
      render :partial=>'simple_result'
    else
      render :partial => 'geoslider_update'
    end
  end
  
  protected 
  
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
  
  def itemvalidate
    @xmessage = '' if not @xmessage
    dialog_id = params[:item][:dialog_id].to_i
    dialog = Dialog.find_by_id(dialog_id) if dialog_id
    html_content = params[:item][:html_content].to_s.strip
    subject = params[:item][:subject].to_s.strip
    plain_content = view_context.strip_tags(html_content)
    plain_content.gsub!('&nbsp;','')
    plain_content.strip!
    if params[:js_message_length]
      message_length = params[:js_message_length].to_i
    else
      message_length = plain_content.length
    end
    logger.info("items#itemvalidate length:#{message_length} first_in_thread:#{@item.is_first_in_thread} dialog:#{dialog.class if dialog} max_characters:#{dialog.settings_with_period["max_characters"].to_i if dialog}")
    if plain_content == '' and @item.media_type =='text' and ((dialog and dialog.settings_with_period["required_message"]) or subject != '')
      @xmessage += "Please include at least a brief message<br>"
    elsif @item.short_content == ''
      @xmessage += "Please include at least a short message<br>"
    elsif @item.is_first_in_thread and dialog and dialog.settings_with_period["max_words"].to_i > 0 and 1.0 * plain_content.scan(/(\w|-)+/).size > dialog.settings_with_period["max_words"] * 1.05
      @xmessage += "That's too many words"
    elsif @item.is_first_in_thread and dialog and dialog.settings_with_period["max_characters"].to_i > 0 and 1.0 * message_length > dialog.settings_with_period["max_characters"] * 1.05
      @xmessage += "The maximum message length is #{dialog.settings_with_period["max_characters"]} characters<br>"
    elsif dialog and dialog.settings_with_period["required_subject"] and subject.to_s == '' and html_content.gsub(/<\/?[^>]*>/, "").strip != ''
      @xmessage += "Please choose a subject line<br>"
    #elsif subject != '' and ((subject[0,3] != 'Re:' and subject.length > 48) or subject.length > 52)
    #  @xmessage += "Maximum 48 characters for the subject line, please<br>"        
    else
      return true
    end  
    #@xmessage = "<p style=\"color:#f00;text-align:center;font-weight:bold;font-size:16px;border:1px solid #f00;padding:10px;\"><br>#{@xmessage}</p>"
    #@xmessage = "<p style=\"color:#f00;\"><br>#{@xmessage}</p>"
    return false
  end
  
  def itemprocess
    logger.info("items#itemprocess media_type:#{@item.media_type}") 
    
    @send_to = params[:send_to]
    #if @send_to[0] == 'G'
    #  @item.group_id = @send_to[1,].to_i
    #else  
    #  @item.group_id = params[:item][:group_id].to_i
    #end  
    #@item.group_id = 0 if @item.group_id.to_i < 0
    #if @send_to[0] == 'D'
    #  @item.dialog_id = @send_to[1,].to_i
    #else  
    #  @item.dialog_id = params[:item][:dialog_id].to_i
    #end  
    
    @item.group_id = params[:item][:group_id].to_i
    @item.group_id = 0 if @item.group_id.to_i < 0
    @item.dialog_id = params[:item][:dialog_id].to_i
    @item.dialog_id = 0 if @item.dialog_id.to_i < 0
    if @item.dialog_id > 0
      @dialog = Dialog.find_by_id(@item.dialog_id)
      @item.group_id = @dialog.group_id.to_i if @dialog and @item.group_id.to_i == 0
    end
    
    if @item.is_first_in_thread and params[:subgroup_add].to_s != ''
      #-- A subgroup is added to this message
      subgroup_add = params[:subgroup_add]
      @item.subgroup_list.add(subgroup_add)
    end  
    
    if @item.group_id > 0 and @item.is_first_in_thread
      #-- If this is a root message in a group, we might need to add a dummy 'none' subgroup
      xgroup = Group.find_by_id(@item.group_id)
      if xgroup
        if @item.subgroup_list == ''
          #-- If there's no subgroup set, use none
          @item.subgroup_list = 'none'          
        else  
          users_subgroups = xgroup.mysubtags(current_participant)
          insub = false
          for xsub in @item.subgroup_list
            if users_subgroups.include?(xsub)
              insub = true
            end  
          end  
          if not insub
            @item.subgroup_list.add('none')        
          end
        end 
      end
    end 
    
    if @item.is_first_in_thread and @item.subgroup_list.to_s != '' and not @item.new_record? and @item.id.to_i > 0
      #-- Add it to any other messages in that thread, if it isn't already there. This is really if it was changed after the fact.
      subitems = Item.where(:first_in_thread=>@item.id).where(:is_first_in_thread=>false)
      for subitem in subitems
        subitem.subgroup_list = @item.subgroup_list
        subitem.save
      end
    end  
    
    if @send_to == 'wall'
      @item.posted_to_forum = false
    else
      @item.posted_to_forum = true      
    end    
    
    if @item.media_type == 'video' or @item.media_type == 'audio'
      if @item.link.to_s != ''
        response = get_embedly(@item.link)
        if response
          @item.oembed_response = response
          if response['html'] and response['html'].to_s != ''
            @item.embed_code = response['html']
          end  
        end
      end
    elsif @item.media_type == 'picture'
      itempicupload
    else
      logger.info("items#itemprocess before clean:#{@item.html_content.inspect}") 
      #@item.html_content = Sanitize.clean(@item.html_content, 
      #  :elements => ['a', 'p', 'br', 'u', 'b', 'em', 'strong', 'ul', 'li', 'h1', 'h2', 'h3','table','tr','tbody','td','img'],
      #  :attributes => {'a' => ['href'], 'img' => ['src', 'alt', 'width', 'height', 'align', 'vspace', 'hspace', 'style']},
      #  :protocols => {'a' => {'href' => ['http', 'https', 'mailto', :relative]}, 'img' => {'src'  => ['http', 'https', :relative]} },
      #  :allow_comments => false,
      #  :output => :html
      #)
      #:remove_contents => ['style']
      #-- Make all links open a new window
      logger.info("items#itemprocess before regex:#{@item.html_content.inspect}") 
      @item.html_content.gsub!(/a href/im,'a target="_blank" href')
      logger.info("items#itemprocess after regex:#{@item.html_content.inspect}") 
    end
  end  
  
  def itempicupload
    #-- Put any uploaded or grabbed picture in the right place
    @participant_id = current_participant.id
    got_file = false
    tempfilepath = "/tmp/#{current_participant.id}_#{Time.now.to_i}"
    `rm -f #{tempfilepath}`    
    logger.info("items#itempicupload tempfilepath:#{tempfilepath}")
    
    if params[:uploadfile] and params[:uploadfile].original_filename.to_s != ""
      #-- We got an uploaded file
      original_filename = params[:uploadfile].original_filename.to_s
      logger.info("items#itempicupload uploaded file:#{original_filename}")      
      f = File.new(tempfilepath, "wb")
      f.write params[:uploadfile].read
      f.close
    elsif params[:photo_id].to_i > 0
      #-- Use one of the user's photos
      tempfilepath = "#{DATADIR}/photos/#{@participant_id}/#{params[:photo_id]}.jpg"     
      logger.info("items#itempicupload use existing photo at: #{tempfilepath}")      
    elsif @item.link != ''
      #-- Grab file from url
      logger.info("items#itempicupload grabbing:#{@item.link}")      
      #-- Parse the URL into its component parts
      begin
        uri = URI.parse(@item.link)
      rescue
        @error_message = "The URL isn't right: " + $!.to_s
        return
      end
      if uri.query.to_s != ""
        path = uri.path + '?' + uri.query
      else
        path = uri.path
      end  
      #-- Prepare a request object  
      req = Net::HTTP::Get.new(path)
      #-- Set headers
      req.add_field("User-Agent", "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; en-US) AppleWebKit/533.2 (KHTML, like Gecko) Chrome/5.0.342.7 Safari/533.2")
      #-- Make the actual http request
      response = nil
      jstart = Time.now.to_i
      begin
        Timeout::timeout(10) do 
          response = Net::HTTP.new(uri.host, uri.port).start do |http|
            http.request(req)
          end
        end 
      rescue Timeout::Error
        @error_message = "Timeout for URL: " + $!.to_s
        return      
      rescue
        @error_message = "Error in http call: " + $!.to_s
        return      
      end
      if response
        #@http_result = "#{response.code} #{response.message}"
        #print "#{@camera.id} Response Code: #{response.code} #{response.message}\n" if @debug
        #response.each {|key,val| printf "%-14s: %-40.40s\n", key, val}
        logger.info("items#itempicupload response code:#{response.code}")      
        if response.code.to_i != 200
          @error_message = "HTTP failure when accessing URL: " + $!.to_s
          return
        end  
      else
        @error_message = "No response when accessing URL\n"
        return
      end
      f = File.new(tempfilepath, "wb")
      f.write response.body
      f.close
    else
      logger.info("items#itempicupload apparently didn't get anything: #{params[:uploadfile].inspect}")      
    end    
       
    if not File.exist?(tempfilepath)
      logger.info("items#itempicupload no picture found at #{tempfilepath}")
      return
    end  
      
    if not (flash[:alert] or flash.now[:alert])
      if not @item.id  
        @item.save
      end

      @item.add_image(tempfilepath)
    end
    
    `rm -f #{tempfilepath}`
    
    
  end

  def update_prefix
    #-- Update the current dialog, and the prefix and base url 
    logger.info("items#update_prefix")   
    if @group
      if @is_member
        session[:group_id] = @group.id
        session[:group_name] = @group.name
        session[:group_prefix] = @group.shortname
        session[:group_is_member] = true
      else
        session[:group_id] = 0
        session[:group_name] = ''
        session[:group_prefix] = ''
        session[:group_is_member] = false
      end
      session[:cur_prefix] = @group.shortname
      session[:dialog_id] = 0
      session[:dialog_name] = ''
      session[:dialog_prefix] = ''
      if session[:cur_prefix] != ''
        session[:cur_baseurl] = "http://" + session[:cur_prefix] + "." + ROOTDOMAIN    
      else
        session[:cur_baseurl] = "http://" + BASEDOMAIN    
      end
    end
    if @dialog
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
        session[:cur_baseurl] = "http://" + session[:cur_prefix] + "." + ROOTDOMAIN    
      else
        session[:cur_baseurl] = "http://" + BASEDOMAIN    
      end
    end 
  end
  
  def item_params
    params.require(:item).permit(:item_type, :media_type, :group_id, :dialog_id, :period_id, :subject, :short_content, :html_content, :link, :reply_to, :geo_level, :censored)
  end
    
end
