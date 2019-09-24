require 'will_paginate/array'

class ItemsController < ApplicationController

  layout "front"
  before_action :authenticate_user_from_token!, :except=>[:pubgallery]
  before_action :authenticate_participant!, :except=>[:pubgallery,:view]

  def index
    list  
  end  

  def list
    #-- Return the items to show on the page
    @from = params[:from] || ''
    @ratings = (params[:ratings].to_i == 1)
    @sortby = params[:sortby] || "items.id desc"
    @perscr = params[:perscr].to_i || 25
    @threads = params[:threads] || ''
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
    @posted_by_refugee = (params[:posted_by_refugee].to_i == 1)
    @rated_by_country_code = (params[:rated_by_country_code] || '').to_s
    @rated_by_admin1uniq = (params[:rated_by_admin1uniq] || '').to_s
    @rated_by_metro_area_id = (params[:rated_by_metro_area_id] || 0).to_i
    @rated_by_indigenous = (params[:rated_by_indigenous].to_i == 1)
    @rated_by_other_minority = (params[:rated_by_other_minority].to_i == 1)
    @rated_by_veteran = (params[:rated_by_veteran].to_i == 1)
    @rated_by_interfaith = (params[:rated_by_interfaith].to_i == 1)
    @rated_by_refugee = (params[:rated_by_refugee].to_i == 1)
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
      @participant_id = @participant.id
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
    
    crit = {}
    crit[:dialog_id] = 0
    crit[:period_id] = 0
    crit[:group_id] = 0  
    crit[:posted_by] = @posted_by 
          
    if true      
      #-- Get the records, while adding up the stats on the fly

      items,ratings,@title = Item.get_items(crit,current_participant,@rootonly)
      @itemsproc,@extras = Item.get_itemsproc(items,ratings,current_participant.id,@rootonly)
      @items = Item.get_sorted(items,@itemsproc,@sortby,@rootonly)
                  
    elsif true
      # old way
      
      @items, @itemsproc, @extras = Item.list_and_results(@limit_group,@dialog_id,@period_id,@posted_by,@posted_meta,@rated_meta,@rootonly,@sortby,current_participant,true,0,'','',@posted_by_country_code,@posted_by_admin1uniq,@posted_by_metro_area_id,@rated_by_country_code,@rated_by_admin1uniq,@rated_by_metro_area_id,@tag,@subgroup,false,'','',@want_crosstalk,@posted_by_indigenous,@posted_by_other_minority,@posted_by_veteran,@posted_by_interfaith,@posted_by_refugee,@rated_by_indigenous,@rated_by_other_minority,@rated_by_veteran,@rated_by_interfaith,@rated_by_refugee)
      
      #logger.info("items_controller#list @items: #{@items.inspect}")
      
    else
      # even older way
        
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
  
  def list_api
    #-- Get some items in a simplified manner, over the API, for apps
    
    @messtag = params[:messtag].to_s
    
    #items = Item.where(is_first_in_thread: true)
    #if @tag != ''
    #  items = items.tagged_with(@messtag)
    #end
    #items = items.order("id desc").limit(5)

    rootonly = true
    sortby = '*value*'
    crit = {
      'messtag': @messtag
    }

    items1,ratings,title = Item.get_items(crit,current_participant,rootonly)
    itemsproc,extras = Item.get_itemsproc(items1,ratings,current_participant.id,rootonly)
    items = Item.get_sorted(items1,itemsproc,sortby,rootonly)
    
    @items = []
    own_items = []
    other_items = []
    
    xcount = 0
    
    for item in items
      if item.has_picture
        img_link = "https://#{BASEDOMAIN}/images/data/items/#{item.id}/big.jpg"
      elsif item.participant.picture.url.to_s != ''
        img_link = item.participant.picture.url
      else
        img_link = ""
      end
      plain_content = view_context.strip_tags(item.html_content.to_s).strip      # or sanitize(html_string, tags:[])
      content_without_hash = plain_content.gsub(/\B[#]\S+\b/, '').strip
      if content_without_hash.length > 190
        content_without_hash = content_without_hash[0,190]
        item_has_more = 1
      else
        item_has_more = 0
      end
      
      @comments = []
      comments = Item.where(first_in_thread: item.id, is_first_in_thread: false).order('id')
      for comment in comments
        plain_content = view_context.strip_tags(comment.html_content.to_s).strip
        plain_content.gsub!(/\B[#]\S+\b/, '')
        if plain_content.length > 500
          com_content = plain_content[0,487] + '...'
          has_more = 1
        else
          com_content = plain_content
          has_more = 0
        end
        com = {
          'id': comment.id,
          'created_at': comment.created_at,
          'posted_by': comment.posted_by,
          'posted_by_user': comment.participant.name,
          'content': com_content,
          'has_more': has_more
        }
        @comments << com
      end
      
      has_voted = item.has_voted(current_participant)
      
      rec = {
        'id': item.id,
        'created_at': item.created_at,
        'posted_by': item.posted_by,
        'posted_by_user': item.participant.name,
        'subject': item.subject,
        'short_content': item.short_content,
        'html_content': item.html_content,
        'content_without_hash': content_without_hash,
        'approval': item.approval,
        'interest': item.interest,
        'has_voted': has_voted,
        'media_type': item.media_type,
        'has_picture': item.has_picture,
        'link': img_link,
        'reply_to': item.reply_to,
        'comments': @comments,
        'num_comments': @comments.length,
        'has_more': item_has_more,
      }
      
      rating = Rating.where(item_id: item.id, participant_id: current_participant.id).last
      rec['thumbs'] = rating ? rating.approval.to_i : 0
      
      if !has_voted
        logger.info("items#list_api !vote subject:#{item.short_content} num_comments:#{@comments.length}")
        #@items << rec
        if current_participant.id == item.posted_by
          own_items << rec
        else
          other_items << rec
        end
        xcount += 1
        if xcount >= 12
          break
        end
      elsif current_participant.id == item.posted_by
        logger.info("items#list_api voted subject:#{item.short_content} num_comments:#{@comments.length}")
      end
    
    end
    
    #logger.info("items#list_api own_items[0]: #{own_items[0]}")
    #logger.info("items#list_api own_items: #{own_items.collect{|i| i[:id]}}")
    own_items_sorted = own_items.sort {|a,b| b[:id]<=>a[:id]}
    #logger.info("items#list_api own_items_sorted: #{own_items_sorted.collect{|i| i[:id]}}")
    
    @items = own_items_sorted + other_items
    
    logger.info("items#list_api returning #{@items.length} items")
    
    render json: @items
  end
  
  def report_api
    #-- Report a post
    item_id = params[:id].to_i
    text = params[:text]
    posted_by = params[:posted_by].to_i
    logger.info("items#report_api")
    subject = "App post reported"
    
    item = Item.find_by_id(item_id)
    reporter = Participant.find_by_id(posted_by)
    
    message = "<p>Item ##{item_id}:#{item.subject} reported by user ##{posted_by}:#{reporter.email}</p><p>#{text}</p>"
    
    toemail = 'appreport@intermix.org'
    
    cdata = {}
    email = SystemMailer.generic(SYSTEM_SENDER, toemail, subject, message, cdata)    
    begin
      logger.info("items#report_api delivering email to #{toemail}")
      email.deliver
    rescue
    end
    render json: {'result': 'ok'}
  end
  
  def new
    #-- screen for a new item, either new thread or a reply
    @from = params[:from] || ''
    @reply_to = params[:reply_to].to_i
    @item = Item.new(:media_type=>'text',:link=>'https://',:reply_to=>@reply_to,html_content: '')
    @item.geo_level = params[:geo_level] if params[:geo_level].to_s != ''
    @items_length = params[:items_length].to_i
    @subgroup = params[:subgroup].to_s
    @comtag = params[:comtag].to_s
    @messtag = params[:messtag].to_s
    @nvaction = (params[:nvaction].to_i == 1) ? true : false
    @conversation_id = params[:conversation_id].to_i
    logger.info("items#new @comtag:#{@comtag} @messtag:#{@messtag}") 
    @meta_3 = params[:meta_3].to_i    # gender
    @meta_5 = params[:meta_5].to_i    # age
    
    if @item.reply_to.to_i > 0
      @olditem = Item.find_by_id(@item.reply_to)
    end
    
    @in_conversation =  (@conversation_id > 0)
      
    if false and @conversation_id == 0
      # Check if the user is in a community that is in a conversation. If so, count it for that conversation
      # Eh, but which one if there are several?
      for com_tag in current_participant.tag_list_downcase
        community = Community.find_by_tagname(com_tag)
        if community.conversations and community.conversations.length > 0
          @conversation_id = community.conversations[0].id
          break
        end
      end
    end

    # NB: If not in other conversation, if one of the other of the user's nations is tagged, including in international conversation
    # WHERE? HOW?
       
    @item.conversation_id = @conversation_id   
    
    if params[:group_id].to_i > 0
      @item.group_id = params[:group_id] 
    elsif @olditem and @olditem.group_id.to_i > 0
      @group_id = @olditem.group_id
    else
      @item.group_id = 0      
    end
    if params[:dialog_id].to_i > 0
      @dialog_id = params[:dialog_id].to_i
      @item.group_id = session[:group_id].to_i if @item.group_id == 0
    elsif @olditem and @olditem.dialog_id.to_i > 0
      @dialog_id = @olditem.dialog_id
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
      render plain: "<p>Your membership is not active</p>"
      return
    end    
    
    tags = []
    tags_downcase = []
    
    @is_com_member = false
    if @comtag != ''
      @community = Community.where(tagname: @comtag).first
      if current_participant.tag_list_downcase.include?(@comtag.downcase)
        @is_com_member = true
      end
    end
        
    if @item.reply_to.to_i > 0
      @item.is_first_in_thread = false 
      #@olditem = Item.find_by_id(@item.reply_to)
      if @olditem
        @item.first_in_thread = @olditem.first_in_thread
        if @olditem.subject.to_s != '' and @olditem.subject[0,3] != 'Re:' and @olditem.subject[0,3] != 're:'
          #@item.subject = "Re: #{@olditem.subject}"[0,48]  
          @item.subject = "Re: #{@olditem.subject}"  
        elsif @olditem.subject != ''
          @item.subject = @olditem.subject 
        end
        
        # Only keep the conversation setting only if we're in the conversation and the current user is a community member
        if @is_com_member and @in_conversation
          @item.conversation_id = @conversation_id
        else
          @item.conversation_id = 0
        end
        
        @item.intra_conv = @olditem.intra_conv
        @item.group_id = @olditem.group_id if @item.group_id.to_i == 0 and @olditem.group_id.to_i > 0
        @item.dialog_id = @olditem.dialog_id if @olditem.dialog_id.to_i > 0
        if @item.dialog_id.to_i > 0
          @dialog = Dialog.find_by_id(@item.dialog_id)
          @dialog_name = (@dialog ? @dialog.name : '???')
          @item.period_id = @dialog.current_period if @dialog
        end  
        @item.subgroup_list = @olditem.subgroup_list if @olditem.subgroup_list.to_s != ''
        
        # Get the message tags from the previous message, if any
        tags = tags + get_tags_from_html(@olditem.html_content)
        tags_downcase = get_tags_from_html(@olditem.html_content,true)
        
        #logger.info("items#new replying. Existing @comtag:#{@comtag}")
        @comtag = @olditem.intra_com if @olditem.intra_com and @olditem.intra_com != 'public'
        #logger.info("items#new replying. Setting @comtag:#{@comtag} based on @olditem.intra_com:#{@olditem.intra_com}")
        @item.intra_com = @comtag if @comtag
        @comtag = @comtag.gsub('@','') if @comtag
        #logger.info("items#new replying. @comtag is now:#{@comtag}")
        
      end
    else
      @item.is_first_in_thread = true
      if @dialog and @dialog.settings_with_period["default_message"].to_s != ''
        @item.html_content = @dialog.settings_with_period["default_message"]
        #@item.short_content = @item.html_content
      end 
      @item.intra_com = "@#{@comtag}" if @comtag
      #@item.subgroup_list = @subgroup if @subgroup.to_s != ''   
      @subgroup_add = @subgroup
    end

    if @item.conversation_id > 0
      # We're in a conversation
      @conversation = Conversation.find_by_id(@item.conversation_id)
      if @conversation
        @conv = @conversation.shortname
        if @in_conversation and not tags_downcase.include? @conv.downcase
          # Add conversation tag only if we're currently in the conversation
          tags << @conv
        end
        # Which community or communities in the conversation is the current user in?
        @conv_own_coms = {}
        for com in @conversation.communities
          if current_participant.tag_list_downcase.include?(com.tagname.downcase)
            @conv_own_coms[com.tagname] = com.fullname
          end
        end
        if @conv_own_coms.length == 1 and @conversation.together_apart == 'apart'
          if not tags_downcase.include? @conv_own_coms.keys[0].downcase
            tags << @conv_own_coms.keys[0]
          end
        end
        if @comtag and @conv_own_coms.has_key?(@comtag)
          @item.representing_com = @comtag
          if not tags_downcase.include? @comtag.downcase
            tags << @comtag
          end
        end
        
        if @conversation.together_apart != ''
          if @item.reply_to.to_i > 0
            if @olditem.together_apart.to_s != ''
              if not tags_downcase.include? @olditem.together_apart.downcase
                tags << @olditem.together_apart
              end
            end
          else
            if not tags_downcase.include? @conversation.together_apart.downcase
              tags << @conversation.together_apart
            end
          end
        end
      end
    end
    
    if @conversation
      @item.intra_conv = @conv if @item.reply_to.to_i == 0    # A reply will keep same setting, conversation only, or not
    end
    
    if not tags.include? 'nvaction'
      tags << 'nvaction' if @nvaction
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
          render plain: "<p>You're not a member of that group</p>"
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
    #if @dialog and @item.reply_to.to_i == 0
    #  if @dialog.active_period and @dialog.active_period.max_messages.to_i > 0
    #    @previous_messages_period = Item.where("posted_by=? and dialog_id=? and period_id=? and (reply_to is null or reply_to=0)",current_participant.id,@dialog.id,@dialog.current_period.to_i).count      
    #    if @previous_messages_period >= @dialog.active_period.max_messages.to_i
    #      render plain: "<p>You've already reached your maximum number of threads for this period</p>"
    #      return
    #    end
    #  end  
    #  if @dialog.max_messages.to_i > 0
    #    @previous_messages = Item.where("posted_by=? and dialog_id=? and (reply_to is null or reply_to=0)",current_participant.id,@dialog.id).count
    #    if @previous_messages >= @dialog.max_messages.to_i
    #      render plain: "<p>You've already reached your maximum number of threads for this discussion</p>"
    #      return
    #    end
    #  end
    #end
    
    if true or @item.reply_to.to_i == 0
      #-- Fill in some default message tags
      tags << 'nvaction' if @nvaction
      if @item.reply_to.to_i > 0 and @olditem
        tags.concat @olditem.tag_list_downcase
      end
      logger.info("items#new tags:#{tags.inspect}") 
      if @meta_3 == 207
          tags << 'VoiceOfMen'    
      elsif @meta_3 == 208
          tags << 'VoiceOfWomen'         
      end
      if @meta_5 == 405
          tags << 'VoiceOfYouth'
      elsif @meta_5 == 406
          tags << 'VoiceOfExperience'
      elsif @meta_5 == 407
          tags << 'VoiceOfWisdom'        
      end
      if current_participant.geocountry
        country_com = Community.where(context: 'nation', context_code:current_participant.geocountry.iso3).first
        if country_com
          country_tag = country_com.tagname
        else
          country_tag = current_participant.geocountry.name
        end
      else
        country_tag = ''
      end
      if @item.geo_level == 'city' and current_participant.city.to_s != ''
        tags << current_participant.city
        if current_participant.admin2uniq.to_s != ''
          tags << current_participant.geoadmin2.name if not tags_downcase.include? current_participant.geoadmin2.name.downcase
        end
        if current_participant.metro_area_id.to_i > 0
          tags << current_participant.metro_area.name if not tags_downcase.include? current_participant.metro_area.name.downcase
        end
        if current_participant.admin1uniq.to_s != ''
          tags << current_participant.geoadmin1.name if not tags_downcase.include? current_participant.geoadmin1.name.downcase
        end
        if country_tag != ''
          tags << country_tag if not tags_downcase.include? country_tag.downcase
        end
      elsif @item.geo_level == 'county' and current_participant.admin2uniq.to_s != ''
        tags << current_participant.geoadmin2.name
        if current_participant.metro_area_id.to_i > 0
          tags << current_participant.metro_area.name if not tags_downcase.include? current_participant.metro_area.name.downcase
        end
        if current_participant.admin1uniq.to_s != ''
          tags << current_participant.geoadmin1.name if not tags_downcase.include? current_participant.geoadmin1.name.downcase
        end
        if country_tag != ''
          tags << country_tag if not tags_downcase.include? country_tag.downcase
        end
      elsif @item.geo_level == 'metro' and current_participant.metro_area_id.to_i > 0
        tags << current_participant.metro_area.name
        if current_participant.admin1uniq.to_s != ''
          tags << current_participant.geoadmin1.name if not tags_downcase.include? current_participant.geoadmin1.name.downcase
        end
        if country_tag != ''
          tags << country_tag if not tags_downcase.include? country_tag.downcase
        end
      elsif @item.geo_level == 'state' and current_participant.admin1uniq.to_s != ''
        tags << current_participant.geoadmin1.name
        if country_tag != ''
          tags << country_tag if not tags_downcase.include? country_tag.downcase
        end
      elsif (@item.geo_level == 'nation' or (@conversation and @conversation.context=='nation')) and country_tag != ''
        # Country. Look for a matching community, and use its tag
        tags << country_tag if not tags_downcase.include? country_tag.downcase
      end
      tags << @messtag if @messtag.to_s != '' and !tags.include?(@messtag) and @messtag != 'my' and @messtag != '*my*' and not tags_downcase.include? @messtag.downcase
      tags << @comtag if @comtag.to_s != '' and !tags.include?(@comtag) and @comtag != 'my' and @comtag != '*my*' and not tags_downcase.include? @comtag.downcase
      
      if @item.is_first_in_thread and @community 
        #-- Add tags for this and any parent communities
        if @community.autotags.to_s != ''
          autotags = @community.autotags.gsub('#','').split(/\W+/)
          for autotag in autotags
            tags << autotag if not tags_downcase.include? autotag.downcase
          end        
        end
        com = @community
        while com.is_sub do
          parent = Community.find_by_id(com.sub_of)        
          if parent.autotags.to_s != ''
            autotags = parent.autotags.gsub('#','').split(/\W+/)
            for autotag in autotags
              tags << autotag if not tags_downcase.include? autotag.downcase
            end
          end
          com = parent
        end
      end
    end
    
    logger.info("items#new tags:#{tags.inspect}") 
    tagtext = ''.dup
    has_done = {}
    tags.uniq.each do |tag|
      if not has_done.has_key? tag.downcase
        tagtext += ' ' if tagtext != ''
        tag = tag.gsub(/[^0-9A-za-z_]/i,'')
        tagtext += "##{tag}"
        has_done[tag.downcase] = true
      end
    end
    @item.html_content += "<p><br><br>#{tagtext}</p>"
    
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
    @item.link = '' if @item.link == 'https://'
    @item.item_type = 'message'
    @item.posted_by = current_participant.id
    @item.geo_level = params[:geo_level] if params[:geo_level]

    if current_participant.status != 'active'
      #-- Make sure this is an active member
      results = {'error'=>true,'message'=>"Your membership is not active",'item_id'=>0}        
      render :json=>results, :layout=>false
      return
    end

    tags_in_html = get_tags_from_html(@item.html_content,true)
    logger.info("items#create tags_in_html:#{tags_in_html.inspect}")
    
    if @item.conversation_id.to_i > 0
      @conversation = Conversation.find_by_id(@item.conversation_id)      
      tag = '#' + @conversation.shortname
      logger.info("items#create conversation #{@conversation.id} should have tag #{tag}. together_apart:#{@conversation.together_apart} representing_com:#{@item.representing_com}")      
      if not tags_in_html.include? @conversation.shortname.downcase
        # If the conversation hashtag is missing, add it back in before the last </p>
        logger.info("items#create conversation tag added at the end")
        array_of_pieces = @item.html_content.rpartition '</p>'
        ( array_of_pieces[(array_of_pieces.find_index '</p>')] = " #{tag}</p>" ) rescue nil
        @item.html_content = array_of_pieces.join  
        tags_in_html = get_tags_from_html(@item.html_content,true)
      end

      if @conversation.together_apart == 'apart' and @item.representing_com.to_s != ''
        # If there's a represent community, include the hash tag, if not there, if it is in the apart period
        tag = '#' + @item.representing_com
        #if not @item.html_content.include? tag
        if not tags_in_html.include? @item.representing_com.downcase
          # If it is not already there. It would be if there was only one community they were a member of
          logger.info("items#create representing_com tag not already there")
          if @item.html_content.include? "##{@conversation.shortname}"
            # The conversation tag is there. Put it right after that
            @item.html_content.gsub!("##{@conversation.shortname}", "##{@conversation.shortname} #{tag}")
            logger.info("items#create representing_com tag added after conversation tag")
          else
            # Put it before the last </p>
            array_of_pieces = @item.html_content.rpartition '</p>'
            ( array_of_pieces[(array_of_pieces.find_index '</p>')] = "#{tag}</p>" ) rescue nil
            @item.html_content = array_of_pieces.join  
            logger.info("items#create representing_com tag added at the end")
          end
        end
      end
      
      if @conversation.together_apart != '' and @item.reply_to.to_i == 0
        # Root messages in conversation are marked with togther or apart
        @item.together_apart = @conversation.together_apart
      end
      
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
        @item.together_apart = @olditem.together_apart
      end
      if @conversation
        # If reply is from somebody outside the conversation, flag it
        @in_conversation = false
        for com in @conversation.communities
          if current_participant.tag_list_downcase.include?(com.tagname.downcase)
            @in_conversation = true
          end
        end
        @item.outside_conv_reply = (not @in_conversation)
      end
    else
      @item.is_first_in_thread = true 
      @item.first_in_thread_group_id = @item.group_id
    end    
    logger.info("items#create by #{@item.posted_by}")
    
    if @item.together_apart.to_s != ''
      # add a together / apart tag, if not already there
      tag = '#' + @item.together_apart
      if not @item.html_content.include? tag
        # Put it before the last </p>
        array_of_pieces = @item.html_content.rpartition '</p>'
        ( array_of_pieces[(array_of_pieces.find_index '</p>')] = "#{tag}</p>" ) rescue nil
        @item.html_content = array_of_pieces.join  
      end
    end
    
    if @item.group_id.to_i == 0
      @item.group_id = GLOBAL_GROUP_ID
    end

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
      
      if @item.reply_to.to_i > 0 
        #-- If it is a reply, they'll have interest rating 4 on whatever they replied to, and the top of the thread, if not the same  
        #-- unless it is themselves
        orig_item = Item.find_by_id(@item.reply_to)
        if orig_item and current_participant.id != orig_item.posted_by
          rating = Rating.where(item_id: @item.reply_to.to_i, participant_id: current_participant.id, rating_type: 'AllRatings', group_id: orig_item.group_id, dialog_id: orig_item.dialog_id, dialog_round_id: orig_item.dialog_round_id).first_or_initialize
          if rating.interest != 4
            rating.interest = 4
            rating.save
          end
        end
        if @item.first_in_thread.to_i != @item.reply_to.to_i
          orig_item = Item.find_by_id(@item.first_in_thread)
          if orig_item and current_participant.id != orig_item.posted_by
            rating = Rating.where(item_id: @item.first_in_thread.to_i, participant_id: current_participant.id, rating_type: 'AllRatings', group_id: orig_item.group_id, dialog_id: orig_item.dialog_id, dialog_round_id: orig_item.dialog_round_id).first_or_initialize
            if rating.interest != 4
              rating.interest = 4
              rating.save
            end
          end
        end
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
  
  def create_api
    #-- Create an item, called remotely by json, which should be turned into params automatically
    #-- We should be receiving an auth_token, login in the user
    
    #auth_token = params[:auth_token].presence
    #participant       = auth_token && Participant.find_by_authentication_token(auth_token.to_s)
    #if participant
    #  sign_in participant
    #end
    
    posted_by = params[:posted_by].to_i
    subject = params[:subject].to_s
    short_content = params[:short_content].to_s
    
    if not participant_signed_in? or current_participant.id != posted_by
      render json: {'result': 'error: invalid user'}
      return
    end
    
    @item = Item.new()
    @item.item_type = 'message'
    @item.media_type = 'picture'
    @item.posted_by = current_participant.id
    @item.subject = subject
    @item.short_content = short_content
    @item.html_content = @item.short_content
    @item.is_first_in_thread = true 
    
    itemprocess
    
    @item.save!
    @item.first_in_thread = @item.id    
    if @item.save
      render json: {'result': 'success', 'item_id': @item.id}
      return
    else
      render json: {'result': 'error: something went wrong'}
      return
    end
    
  end
  
  def update
    @from = params[:from] || ''
    @item = Item.find(params[:id])
    @item.link = '' if @item.link == 'https://'
    
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
      render plain: "Can't delete this item. It has replies"
      return
    end  
    @item.destroy
    render plain: "The item has been deleted"    
  end  
  
  def view
    #-- Show an individual post
    return if redirect_if_not_voh
    @from = params[:from] || 'individual'
    @item_id = params[:id]
    @item = Item.includes([:dialog,:group,{:participant=>{:metamap_node_participants=>:metamap_node}},:item_rating_summary])
    
    if not @item
      render :status => 404
      return
    end
    
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
    
    if params[:thumb].to_i != 0
      # If a thumb vote is given, record it before showing the item
      # If we already had a vote, only record if it changes direction, positive/negative
      vote = params[:thumb].to_i
      rateitem(@item, vote, true)
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
    return if redirect_if_not_voh
    @from = params[:from] || 'thread'
    @item_id = params[:id]
    @exp_item_id = (params[:exp_item_id] || 0).to_i
    @item = Item.includes([:dialog,:group,{:participant=>{:metamap_node_participants=>:metamap_node}},:item_rating_summary]).find(@item_id)
    @conversation_id = params[:conversation_id].to_i
    @inline = (params[:inline].to_i == 1)
    
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

    if @conversation_id > 0
      @replies = Item.where(is_first_in_thread: false, first_in_thread: @first_item.id, conversation_id: @conversation_id).order("id")
    else
      @replies = Item.where(is_first_in_thread: false, first_in_thread: @first_item.id).order("id")
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
    @items, @itemsproc, @extras = Item.list_and_results(@group,@dialog,@period_id,@posted_by,@posted_meta,@rated_meta,@rootonly,@sortby,current_participant,true,0,'','',@posted_by_country_code,@posted_by_admin1uniq,@posted_by_metro_area_id,@rated_by_country_code,@rated_by_admin1uniq,@rated_by_metro_area_id)

    update_last_url
    #update_prefix

    if @inline
      render :action=>'thread', layout: false
    else
      render :action=>'thread'
    end
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
      render plain: ''
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
    
    render plain: vote
  end 
  
  def rateitem(item, vote, from_mail=false, conversation_id=0)
    # Called by fx thumbrate or view to record a vote, without showing any screen
    
    if not item.voting_ok(current_participant.id)
      return
    end    
    
    item_id = item.id
    group_id = item.group_id.to_i
    dialog_id = item.dialog_id.to_i
    is_new = false
    
    # check for comments in that thread
    #com_count = Item.where(posted_by: current_participant.id, is_first_in_thread: false, first_in_thread: item.first_in_thread).count
    # check for comments on that message
    com_count = Item.where(posted_by: current_participant.id, reply_to: item_id).count
    
    #-- See if that user already has rated that item, or create a new rating if they haven't
    rating = Rating.where(item_id: item_id, participant_id: current_participant.id, rating_type: 'AllRatings').first
    if not rating
      is_new = true
      rating = Rating.create(item_id: item_id, participant_id: current_participant.id, rating_type: 'AllRatings', approval: vote, interest: vote.abs)
    end
    
    if conversation_id > 0
      conversation = Conversation.find_by_id(conversation_id)
      if conversation and conversation.is_member_of(current_participant)
        # If we're in a conversation, and the user is a member, only then do we store a conversation with the rating
        rating.conversation_id = conversation_id
      end
    end
    
    if is_new
      # We just saved the initial rating
    elsif rating and from_mail
      #-- If it was from an email, there's only -1 and +1 choice. If we already had a rating, only do something if it changed direction
      # https://intermix.test:3002/items/2111/view?auth_token=Y8fCCBYWx8-ETHcyWGC4&thumb=-1
      if rating.approval and rating.approval.to_i > 0 and vote < 0
        rating.approval = vote    
        rating.interest = vote.abs
      elsif rating.approval and rating.approval.to_i < 0 and vote > 0
        rating.approval = vote    
        rating.interest = vote.abs
      elsif rating.approval
        return       
      end
    elsif rating.approval == vote
      #-- If they clicked on the existing rating, turn it off
      rating.approval = 0    
      rating.interest = 0
    else
      rating.approval = vote    
      rating.interest = vote.abs
    end
    
    if com_count > 0
      rating.interest = 4
    end
    rating.save!
    
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
      
  end
  
  def thumbrate
    #-- rate an item with up or down thumbs
    @from = params[:from] || ''
    item_id = params[:id].to_i
    vote = params[:vote].to_i
    conversation_id = params[:conversation_id].to_i
    logger.info("items#thumbrate item:#{item_id} user:#{current_participant.id} vote:#{vote}")

    item = Item.includes(:dialog,:group).find_by_id(item_id)

    #-- Check if they're allowed to rate it
    if not item.voting_ok(current_participant.id)
      render plain: ''
      return
    end
    
    rateitem(item, vote, false, conversation_id)
    
    render plain: vote
  end   
  
  def get_summary
    @item_id = params[:id]
    items = Item.where(:id=>@item_id).includes(:item_rating_summary,:dialog)
    @item = items[0]    
    @item.item_rating_summary.recalculate(false,@item.dialog) if @item.item_rating_summary
    render :partial=>"rating_summary", :layout=>false, :locals=>{:item=>@item}
  end
  
  def play
    #-- return the code for an embedded item, so it can be played
    @from = params[:from] || ''
    @item_id = params[:id]
    @item = Item.find(@item_id)
    render plain: @item.embed_code
  end  
  
  def pubgallery
    #-- Public gallery
    @group_id = 8
    @items = Item.where("items.group_id=#{@group_id} and items.has_picture=1 and items.media_type='picture'").includes(:participant).order("items.id desc").limit(12)
  end
  
  def censor
    #-- A moderator hits the censor button
    item_id = params[:id]
    item = Item.find_by_id(item_id)
    if not item.censored
      item.censored = true
      item.participant.status = 'inactive'
    else
      item.censored = false  
      item.participant.status = 'active'
    end
    item.save!
    item.participant.save!
    render plain: 'ok'
  end
  
  def follow
    #-- A user will follow a particular item, or rather the root of it
    item_id = params[:id]
    item = Item.find_by_id(item_id)
    #-- Find the root, if it isn't
    if item.is_first_in_thread
      top = item
    else
      top = Item.find_by_id(item.first_in_thread) 
    end
    logger.info("items_controller#follow item:#{item.id} top:#{top.id}")
    
    if true
      item_subscribe = ItemSubscribe.where(item_id: top.id, participant_id:current_user.id).first
      if item_subscribe
        item_subscribe.destroy
      else
        item_subscribe = ItemSubscribe.new(item_id: top.id, participant_id:current_user.id)
        item_subscribe.followed = true
        item_subscribe.save! 
      end
    else
      # What's the default?
      should_be_followed = top.is_followed_by(current_user)    
      item_subscribe = ItemSubscribe.where(item_id: top.id, participant_id:current_user.id).first
      if item_subscribe and should_be_followed
        # If there's already a record, no matter what it says, it shouldn't be necessary (as they naturally follow it), so delete it
        item_subscribe.destroy
      elsif item_subscribe
        # There's a record, but not subscribed, so subscribe it
        item_subscribe.followed = true
        item_subscribe.save!      
      else
        # Create a record to subscribe
        item_subscribe = ItemSubscribe.new(item_id: top.id, participant_id:current_user.id)
        item_subscribe.followed = true
        item_subscribe.save!      
      end
    end

    render plain: 'ok'
  end
  
  def unfollow
    #-- Unfollow the root of a particular item. Called either by ajax or from an email
    item_id = params[:id]
    item = Item.find_by_id(item_id)
    #-- Find the root, if it isn't
    if item.is_first_in_thread
      top = item
    else
      top = Item.find_by_id(item.first_in_thread) 
    end
    logger.info("items_controller#unfollow item:#{item.id} top:#{top.id}")
    
    if true
      item_subscribe = ItemSubscribe.where(item_id: top.id, participant_id:current_user.id).first
      if item_subscribe
        item_subscribe.destroy
      else
        item_subscribe = ItemSubscribe.new(item_id: top.id, participant_id:current_user.id)
        item_subscribe.followed = false
        item_subscribe.save! 
      end      
    else
      # What's the default?
      should_be_followed = top.is_followed_by(current_user)
      item_subscribe = ItemSubscribe.where(item_id: top.id, participant_id:current_user.id).first
      if top.posted_by == current_user.id
        # It's the owner who doesn't want their own thread. Give them special treatment
        if not item_subscribe
          item_subscribe = ItemSubscribe.new(item_id: top.id, participant_id:current_user.id)
        end
        item_subscribe.followed = false
        item_subscribe.save!      
      elsif item_subscribe and not should_be_followed
        # If there's already a record, no matter what it says, it shouldn't be necessary (as they don't aturally follow it), so delete it
        item_subscribe.destroy
      elsif not should_be_followed
        # There isn't a record, and there shouldn't be. Do nothing  
      elsif item_subscribe
        # There's a record, but not unsubscribed, so unsubscribe it
        item_subscribe.followed = false
        item_subscribe.save!      
      else
        # Create a record to unsubscribe
        item_subscribe = ItemSubscribe.new(item_id: top.id, participant_id:current_user.id)
        item_subscribe.followed = false
        item_subscribe.save!      
      end
    end

    if params.has_key? :email
      # We were called from an email
      redirect_to "/items/#{item_id}/view"
    else
      render plain: 'ok'
    end
  end
  
  
  
  def geoslider
    #-- The main screen or the geo slider
  end

  def geoslider_update
    # Getting listings and results tailored to the slider in discussions
    # Variables are:
    # geo_level: city, county, metro, state, nation, earth
    # group_level: current, my, all groups. 
  
    # indigenous, other minority, veteran, *interfaith*, refugee

    crit = {}
    show_result = nil
    rootonly = nil

    1.times do
      
      @per_page = (params[:per_page] || 11).to_i
      @page = ( params[:page] || 1 ).to_i
      @page = 1 if @page < 1
      
      show_result = (params[:show_result].to_i == 1)
      @show_result = show_result
      whatchanged = params[:whatchanged].to_s
    
      @in = params['in'].to_s
      crit['in'] = @in
    
      geo_level = params[:geo_level].to_i
      session[:geo_level] = geo_level
      @geo_level = geo_level
      geo_levels = GEO_LEVELS               # {1 => 'city', 2 => 'county', 3 => 'metro', 4 => 'state', 5 => 'nation', 6 => 'planet'}    
      crit[:geo_level] = geo_levels[geo_level]
  
      crit[:conversation_id] = params[:conversation_id].to_i
  
      crit[:gender] = params[:meta_3].to_i
      crit[:age] = params[:meta_5].to_i
    
      crit[:comtag] = params[:comtag].to_s     # Might be blank, *my*, or a tag
      crit[:messtag] = params[:messtag].to_s
      session[:comtag] = crit[:comtag]
      session[:messtag] = crit[:messtag]
      
      nvaction_changed = false
      if params.has_key?(:nvaction) 
        crit[:nvaction] = (params[:nvaction].to_i == 1) ? true : false
        if session.has_key?(:nvaction) and session[:nvaction] != crit[:nvaction]
          nvaction_changed = true
        end
        session[:nvaction] = crit[:nvaction]
        if not @show_result
          #-- Forum page will include nvaction
          crit[:nvaction_included] = true
        elsif params.has_key?(:nvaction_included)
          crit[:nvaction_included] = (params[:nvaction_included].to_i == 1) ? true : false
          session[:nvaction_included] = crit[:nvaction_included]
          logger.info("items#geoslider_update nvaction:#{crit[:nvaction]} nvaction_included:#{crit[:nvaction_included]}")
        end
      end
    
      @datetype = params[:datetype].to_s    # fixed or range
      @datefixed = params[:datefixed].to_s  # day, week, month, [moon ranges, like 2016-03-08_2017-06-23]
      @datefrom = params[:datefrom].to_s    # [date]

      #MOONS = {
      #  '2016-03-08_2017-06-23' => "March 8, 2016 - June 23, 2017",
      #  '2017-06-23_2017-07-23' => "June 23 - July 23, 2017",      
      #MOONS.select{|d| d<Time.now.to_s[0..10]}.invert.to_a,@datefixed)   
      today = Time.now.strftime("%Y-%m-%d")
      cutoff = 1.month.from_now
      @moons = [] 
      xstart = '2016-03-08'
      xmoon = crit[:nvaction] ? 'full' : 'new' 
      moon_recs = Moon.where(new_or_full: xmoon).where("mdate<='#{cutoff}'").order(:mdate)
      for moon_rec in moon_recs
        xend = moon_rec['mdate'].strftime('%Y-%m-%d')
        dend = moon_rec['mdate'].strftime('%B %-d, %Y')
        dstart = xstart.to_date.strftime('%B %-d, %Y')
        xrange = "#{xstart}_#{xend}"
        drange = "#{dstart} - #{dend}"
        if xstart <= today
          @moons << [drange,xrange]
        end
        xstart = xend
      end    
      if @datetype == 'fixed' and nvaction_changed
        @datefixed = 'month'
      end
    
      #-- Checkboxes are also about comtags
      #if params[:check] and params[:check].class == Hash
      #  check = []
      #  if crit[:comtag] != ''
      #    check << crit[:comtag]
      #  end
      #  params[:check].each do |tag,val|
      #    if val.to_i == 1
      #      check << tag
      #    end
      #  end      
      #  crit[:comtag] = check
      #end
    
      session[:datetype] = @datetype.dup
      session[:datefixed] = @datefixed.dup
      session[:datefrom] = @datefrom.dup
      @datefromto = ''
      if @datetype == 'fixed'
        if @datefixed == 'day'
          @datefromuse = (Date.today - 1).to_s
        elsif @datefixed == 'week'
          @datefromuse = (Date.today - 7).to_s
        elsif @datefixed == 'month'
          @datefromuse = (Date.today - 30).to_s
        elsif /_/ =~ @datefixed   
          xarr = @datefixed.split('_')
          @datefromuse = xarr[0]
          @datefromto = xarr[1]
        end
        logger.info("items#geoslider_update set datefrom to #{@datefromuse} based on datetype:#{@datetype} datefixed:#{@datefixed}")
      else
        @datefromuse = @datefrom.dup    
        logger.info("items#geoslider_update set datefrom to #{@datefromuse} based on datetype:#{@datetype}")
      end
      crit[:datefromuse] = @datefromuse.dup
      crit[:datefromto] = @datefromto.dup
    
      # NB try to avoid this: items.created_at >= 'Y-m-d 00:00:00'
      
      @conversation_id = crit[:conversation_id].to_i
      @in_conversation = (params[:in_conversation].to_i == 1) ? true : false
      if @conversation_id.to_i > 0
        @conversation = Conversation.find_by_id(@conversation_id)
        #if @conversation
        #  # Check if the user is in any community in the conversation
        #  for com in @conversation.communities
        #    if current_participant.tag_list.include?(com.tagname)
        #      @in_conversation = true
        #    end
        #  end
        #end
      end
      
      @perspective = params[:perspective]
      crit[:perspective] = @perspective

      @comtag = ""
      if crit[:comtag] != '' and crit[:comtag] != '*my*'
        @comtag = crit[:comtag]
      end
      
      if session.has_key?(:community_list)
        @community_list = session['community_list']
      else
        @community_list = []
      end
      
      #if @conversation
      #  # What's their perspective? = @comtag
      #  if @comtag and @comtag.to_s != ''
      #    # A tag has been selected. See if they're a member
      #    if not current_participant.tag_list.include?(@comtag)
      #      @comtag = ""
      #    end
      #  elsif session.has_key?("cur_perspective_#{@conversation.id}")
      #    # Does the user already have a perspective
      #    comtag = session["cur_perspective_#{@conversation.id}"]
      #    if current_participant.tag_list.include?(comtag)
      #      @comtag = comtag
      #    end
      #  end    
      #else
      #  # crit[:comtag] Might be blank, *my*, or a tag
      #end

      if crit[:comtag].to_s != '' and crit[:comtag] != '*my*'
        @community = Community.find_by_tagname(crit[:comtag])
      end
                    
      @dialog_id = VOH_DISCUSSION_ID    
      @dialog = Dialog.find_by_id(@dialog_id) if @dialog_id > 0
    
      @first = params[:first].to_i    # 1 if we got here when the page loads, rather than when parameters changed
    
      @showing_options = params[:showing_options] # less or more

      @threads = params[:threads]
      session[:list_threads] = @threads
      if @threads == '' or @threads == 'tree' or @threads == 'root'
        rootonly = true
      else
        rootonly = false
      end

      #-- See how many total posts there are in the selected period, to be able to do a graphic
      all_posts = Item.where(nil)
      all_posts = all_posts.where(:is_first_in_thread => true) if rootonly
      #all_posts = all_posts.where(dialog_id: crit[:dialog_id]) if crit[:dialog_id] > 0
      all_posts = all_posts.where("items.created_at >= ?", crit[:datefromuse])
      @num_all_posts = all_posts.count
      # SELECT COUNT(*) FROM `items` WHERE `items`.`is_first_in_thread` = 1 AND (items.created_at >= '2017-05-21')
      
      @title = ""
      crit[:show_result] = show_result

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
        gender_single = {207=>"Men",208=>"Women"} 
    
        if age > 0 and gender > 0
          # One particular result
          age_id = age
          age_name = MetamapNode.where(id: age).first.name_as_group
          gender_id = gender
          #gender_name = MetamapNode.where(id: gender).first.name
          gender_name = gender_pos[gender_id]
          if gender_id==208 and @community and @community.voice_of_women.to_s != ''
            gender_name = @community.voice_of_women
          elsif gender_id==207 and @community and @community.voice_of_men.to_s != ''
            gender_name = @community.voice_of_men
          end
          name = "#{gender_name} #{age_name}"
          item = nil
          iproc = nil
        
          crit[:age] = age_id
          crit[:gender] = gender_id
          items,ratings,@title = Item.get_items(crit,current_participant)
          @itemsproc, @extras = Item.get_itemsproc(items,ratings,current_participant.id)
          @sortby = '*value*'
          @items = Item.get_sorted(items,@itemsproc,@sortby,false)
          if @items.length > 0 and ratings.length > 0
            if @itemsproc.has_key?(@items[0].id) and @itemsproc[@items[0].id]['votes'] > 0 and @itemsproc[@items[0].id]['value'] > 0
              item = @items[0]
              iproc = @itemsproc[item.id]
            end
          end
        
          @data['all'] = {name: name, item: item, iproc: iproc, itemcount: items.length, ratingcount: ratings.length, extras: @extras}
        elsif age == 0 and gender == 0
          # two genders, three ages, and voice of humanity
          # total
          name = "Voice of Humanity-as-One"
          name = @community.voice_of_humanity if @community and @community.voice_of_humanity.to_s != ''          
          item = nil
          iproc = nil        
          items,ratings,@title = Item.get_items(crit,current_participant)
          @itemsproc,@extras = Item.get_itemsproc(items,ratings,current_participant.id)
          @sortby = '*value*'
          @items = Item.get_sorted(items,@itemsproc,@sortby,false)
          if @items.length > 0 and ratings.length > 0
            exp = ""
            #exp = "@items[0].id:#{@items[0].id} @itemsproc[items[0].id]['value']:#{@itemsproc[items[0].id]['value']}"
            #exp = @itemsproc[items[0].id].inspect
            if @itemsproc.has_key?(@items[0].id) and @itemsproc[@items[0].id]['value'] > 0
              item = @items[0]
              iproc = @itemsproc[item.id]
              #exp = iproc.inspect
              #exp = "#{(@items[0]).id}/#{item.id}"
            end
          end
          @data['all'] = {name: name, item: item, iproc: iproc, itemcount: @items.length, ratingcount: ratings.length, extras: @extras}
        
          for gender_rec in genders
            gender_id = gender_rec.id
            gender_name = gender_rec.name_as_group
            code = "#{gender_id}"
            name = "#{gender_name}"
            if gender_id==208 and @community and @community.voice_of_women.to_s != ''
              name = @community.voice_of_women
            elsif gender_id==207 and @community and @community.voice_of_men.to_s != ''
              name = @community.voice_of_men
            end
            if not gender_rec.sumcat
              item = nil
              iproc = nil
              exp = ""
            
              crit[:gender] = gender_id
              crit[:age] = 0
              items,ratings,title = Item.get_items(crit,current_participant)
              @itemsproc,@extras = Item.get_itemsproc(items,ratings,current_participant.id)
              @sortby = '*value*'
              @items = Item.get_sorted(items,@itemsproc,@sortby,false)
              if @items.length > 0 and ratings.length > 0
                if @itemsproc.has_key?(@items[0].id) and @itemsproc[@items[0].id]['value'] > 0
                  item = @items[0]
                  iproc = @itemsproc[item.id]
                end
              end
            
              @data[code] = {name: name, item: item, iproc: iproc, itemcount: @items.length, ratingcount: ratings.length, extras: @extras}
            end
          end
          for age_rec in ages
            age_id = age_rec.id
            age_name = age_rec.name_as_group
            code = "#{age_id}"
            name = "#{age_name}"
            if age_id==405 and @community and @community.voice_of_young.to_s != ''
              name = @community.voice_of_young
            elsif age_id==406 and @community and @community.voice_of_middleage.to_s != ''
              name = @community.voice_of_middleage
            elsif age_id==407 and @community and @community.voice_of_old.to_s != ''
              name = @community.voice_of_old
            end
            if not age_rec.sumcat
              item = nil
              iproc = nil
            
              crit[:age] = age_id
              crit[:gender] = 0
              items,ratings,title = Item.get_items(crit,current_participant)
              @itemsproc,@extras = Item.get_itemsproc(items,ratings,current_participant.id)
              @sortby = '*value*'
              @items = Item.get_sorted(items,@itemsproc,@sortby,false)
              if @items.length > 0 and ratings.length > 0
                if @itemsproc.has_key?(@items[0].id) and @itemsproc[@items[0].id]['value'] > 0
                  item = @items[0]
                  iproc = @itemsproc[item.id]
                end
              end
            
              @data[code] = {name: name, item: item, iproc: iproc, itemcount: @items.length, ratingcount: ratings.length, extras: @extras}
            end
          end
      
        elsif age > 0 and gender == 0
          # two genders with a particular age
          age_id = age
          age_name = MetamapNode.where(id: age).first.name_as_group
        
          name = "#{age_name}"
          if age_id==405 and @community and @community.voice_of_young.to_s != ''
            name = @community.voice_of_young
          elsif age_id==406 and @community and @community.voice_of_middleage.to_s != ''
            name = @community.voice_of_middleage
          elsif age_id==407 and @community and @community.voice_of_old.to_s != ''
            name = @community.voice_of_old
          end
          item = nil
          iproc = nil        
          crit[:age] = age_id
          items,ratings,@title = Item.get_items(crit,current_participant)
          @itemsproc,@extras = Item.get_itemsproc(items,ratings,current_participant.id)
          @sortby = '*value*'
          @items = Item.get_sorted(items,@itemsproc,@sortby,false)
          if @items.length > 0 and ratings.length > 0
            if @itemsproc.has_key?(@items[0].id) and @itemsproc[@items[0].id]['value'] > 0
              item = @items[0]
              iproc = @itemsproc[item.id]
            end
          end
          @data['all'] = {name: name, item: item, iproc: iproc, itemcount: items.length, ratingcount: ratings.length, extras: @extras}
        
          for gender_rec in genders
            gender_id = gender_rec.id
            #gender_name = gender_rec.name
            gender_name = gender_pos[gender_id]
            if gender_id==208 and @community and @community.voice_of_women.to_s != ''
              gender_name = @community.voice_of_women
            elsif gender_id==207 and @community and @community.voice_of_men.to_s != ''
              gender_name = @community.voice_of_men
            end
            code = "#{age_id}_#{gender_id}"
            name = "#{gender_name} #{age_name}"
            if not gender_rec.sumcat
              item = nil
              iproc = nil
            
              crit[:age] = age_id
              crit[:gender] = gender_id
              items,ratings,title = Item.get_items(crit,current_participant)
              @itemsproc,@extras = Item.get_itemsproc(items,ratings,current_participant.id)
              @sortby = '*value*'
              @items = Item.get_sorted(items,@itemsproc,@sortby,false)
              if @items.length > 0 and ratings.length > 0
                if @itemsproc.has_key?(@items[0].id) and @itemsproc[@items[0].id]['value'] > 0
                  item = @items[0]
                  iproc = @itemsproc[item.id]
                end
              end
            
              @data[code] = {name: name, item: item, iproc: iproc, itemcount: items.length, ratingcount: ratings.length, extras: @extras}
            end
          end
      
        elsif age == 0 and gender > 0
          # three ages with a particular gender
          gender_id = gender
          #gender_name = MetamapNode.where(id: gender).first.name
          gender_name = gender_pos[gender_id]
          if gender_id==208 and @community and @community.voice_of_women.to_s != ''
            gender_name = @community.voice_of_women
          elsif gender_id==207 and @community and @community.voice_of_men.to_s != ''
            gender_name = @community.voice_of_men
          end
        
          name = "Voice of #{gender_single[gender_id]}"
          item = nil
          iproc = nil        
          crit[:gender] = gender_id
          items,ratings,@title = Item.get_items(crit,current_participant)
          @itemsproc,@extras = Item.get_itemsproc(items,ratings,current_participant.id)
          @sortby = '*value*'
          @items = Item.get_sorted(items,@itemsproc,@sortby,false)
          if @items.length > 0 and ratings.length > 0
            if @itemsproc.has_key?(@items[0].id) and @itemsproc[@items[0].id]['value'] > 0
              item = @items[0]
              iproc = @itemsproc[item.id]
            end
          end
          @data['all'] = {name: name, item: item, iproc: iproc, itemcount: items.length, ratingcount: ratings.length, extras: @extras}
        
          for age_rec in ages
            age_id = age_rec.id
            age_name = age_rec.name_as_group
            code = "#{age_id}_#{gender_id}"
            name = "#{gender_name} #{age_name}"
            if not age_rec.sumcat
              item = nil
              iproc = nil
            
              crit[:age] = age_id
              crit[:gender] = gender_id
              items,ratings,title = Item.get_items(crit,current_participant)
              @itemsproc,@extras = Item.get_itemsproc(items,ratings,current_participant.id)
              @sortby = '*value*'
              @items = Item.get_sorted(items,@itemsproc,@sortby,false)
              if @items.length > 0 and ratings.length > 0
                if @itemsproc.has_key?(@items[0].id) and @itemsproc[@items[0].id]['value'] > 0
                  item = @items[0]
                  iproc = @itemsproc[item.id]
                end
              end
            
              @data[code] = {name: name, item: item, iproc: iproc, itemcount: items.length, ratingcount: ratings.length, extras: @extras}
            end
          end
        
        end
      
        # Figure out which new or full moon is next
        now = Time.now.strftime("%Y-%m-%d %H:%M")
        nowdate = Time.now.strftime("%Y-%m-%d")
        nowtime = Time.now.strftime("%H:%M")
        @moon = Moon.where("mdate>='#{nowdate}'").where(mailing_sent: false).order(:mdate).first
        if @moon
          # We want dd-mmm-yyyy at hh:mm am/pm
          moondate = @moon.mdate.strftime("%d-%b-%Y")
          if @moon.mtime.to_s == ""
            moontime = '12:00 pm'
          elsif @moon.mtime == '12:00'
            moontime = "12:00 pm"
          elsif @moon.mtime < '12:00'
            moontime = "#{@moon.mtime} am"
          elsif 
            moontime = ("%02d" % (@moon.mtime[0..1].to_i - 12)) + @moon.mtime[2..4] + 'pm'
          end
          @moontime = moondate + ' ' + moontime
        end

        @crit = crit
    
        render :partial=>'simple_result'
    
      else
        #-- Listing
          
        items,ratings,@title = Item.get_items(crit,current_participant,rootonly)

        #if @num_all_posts == 0 and @first == 1 and @datetype == 'fixed' and @datefixed == 'month'
        if items.length == 0 and @datetype == 'fixed' and @datefixed == 'month'
          #-- If there are no posts in the last month, change to since the beginning
          params[:datetype] = 'range'
          params[:datefrom] = '2016-03-08'
          logger.info("items#geoslider_update no posts in last month, set date to range from 2016-03-08")
          redo
        end
    
        # Add up results for those items and those ratings, to show in the item summaries in the listing
        # I.e. add up the number of interest/approval ratings for each item, do regression to the mean, calculate value, etc
        @itemsproc,@extras = Item.get_itemsproc(items,ratings,current_participant.id,rootonly)
  
        # Items probably need to be sorted, based on the results we calculated
        #sortby = '*value*'
        @sortby = params[:sortby]
        session[:list_sortby] = @sortby
        @items = Item.get_sorted(items,@itemsproc,@sortby,rootonly)

        @batch_size = params[:batch_size].to_i
            
        @batch_level = 1
        @batches = []
        if @items.length > 4
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
        
          if @batches.include?(@batch_size) and @whatchanged != 'threads' and @whatchanged != 'sortby'
            @batch_level = @batches.index(@batch_size) + 1
          elsif params[:batch_level].to_i <= @numbatches and @whatchanged != 'threads' and @whatchanged != 'sortby'
            @batch_level = params[:batch_level].to_i
            @batch_size = @batches[@batch_level-1]
          else  
            @batch_size = 4
          end  
          if @whatchanged == 'threads' and @whatchanged == 'sortby'
            @batch_level = 1
          end
        elsif @batch_size == 0
          @batch_size = @items.length
        end  
      
        @items_length = @items.length
      
        @items = @items.paginate :page=>@page, :per_page => @per_page   
      
        session[:list_batch_level] = @batch_level
        session[:list_batch_size] = @batch_size
        @showmax = @batch_size

        if crit[:nvaction]
          @suggestedtopic = "Nonviolent Action for Human Unity"
        elsif true
          @suggestedtopic = "Human Unity and Diversity"
        else
          @suggestedtopic = session.has_key?(:suggestedtopic) ? session[:suggestedtopic] : ""
        end

        @crit = crit

        render :partial => 'geoslider_update'
  
      end

  
    end  # The one-time loop, for the sake of redo

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
    refugee = (params[:refugee].to_i == 1) ? true : false
    
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
    @posted_by_refugee = refugee
    @rated_by_indigenous = false
    @rated_by_other_minority = false
    @rated_by_veteran = false
    @rated_by_interfaith = false
    @rated_by_refugee = false
    
    @items, @itemsproc, @extras = Item.list_and_results(@group,@dialog_id,@period_id,@posted_by,@posted_meta,@rated_meta,@rootonly,@sortby,current_participant,true,0,'','',@posted_by_country_code,@posted_by_admin1uniq,@posted_by_metro_area_id,@rated_by_country_code,@rated_by_admin1uniq,@rated_by_metro_area_id,@tag,@subgroup,@metabreakdown,@withratings,geo_level,@want_crosstalk,@posted_by_indigenous,@posted_by_other_minority,@posted_by_veteran,@posted_by_interfaith,@posted_by_refugee,@rated_by_indigenous,@rated_by_other_minority,@rated_by_veteran,@rated_by_interfaith,@rated_by_refugee,@posted_by_city,@rated_by_city)
   
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
      #elsif @item.is_first_in_thread and dialog and dialog.settings_with_period["max_words"].to_i > 0 and 1.0 * plain_content.scan(/(\w|-)+/).size > dialog.settings_with_period["max_words"] * 1.05
    elsif dialog and dialog.settings_with_period["max_words"].to_i > 0 and 1.0 * plain_content.scan(/(\w|-)+/).size > dialog.settings_with_period["max_words"] * 1.05
      @xmessage += "That's too many words"
      #elsif @item.is_first_in_thread and dialog and dialog.settings_with_period["max_characters"].to_i > 0 and 1.0 * message_length > dialog.settings_with_period["max_characters"] * 1.05
    elsif dialog and dialog.settings_with_period["max_characters"].to_i > 0 and 1.0 * message_length > dialog.settings_with_period["max_characters"] * 1.05
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
    
    @item.group_id = params[:item] ? params[:item][:group_id].to_i : 0
    @item.group_id = 0 if @item.group_id.to_i < 0
    @item.dialog_id = params[:item] ? params[:item][:dialog_id].to_i : 0
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
    
    # Add/remove tags, based on which hashtags are included in the message text
    logger.info("items#itemprocess html_content:#{@item.html_content.length}") 
    if @item.media_type == 'video' or @item.media_type == 'audio'
      xtxt = @item.short_content
    else
      xtxt = @item.html_content
    end
    xtxt = ActionView::Base.full_sanitizer.sanitize(xtxt)
    logger.info("items#itemprocess xtxt:#{xtxt}") 
    tagmatches = xtxt.scan(/(?:\s|^)(?:#(?!\d+(?:\s|$)))(\w+)(?=\s|$|,|;|:|-|\.|\?)/i).map{|s| s[0]}
    tagmatches2 = []
    for tagmatch in tagmatches
      tagmatch.gsub!(/[^0-9A-za-z_]/,'')
      if tagmatch.length > 14
        tagmatch = tagmatch[0..13]
      end
      tagmatches2 << tagmatch
    end
    logger.info("items#itemprocess tags:#{tagmatches2}") 
    @item.tag_list = tagmatches2
    
    
    if @send_to == 'wall'
      @item.posted_to_forum = false
    else
      @item.posted_to_forum = true      
    end    
    
    if @item.media_type == 'video' or @item.media_type == 'audio'
      if @item.link.to_s != ''
        response = get_oembed(@item.link)
        if response
          logger.info("items#itemprocess oembed response: #{response}")
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
      
      #-- Check for the first link, if any, and try to get a preview
      #urls = @item.html_content.scan(URI.regexp)
      urls = URI.extract(@item.html_content,['http','https'])
      logger.info("items#itemprocess found #{urls.length} links")
      if urls.length > 0
        url = urls[0]
        #logger.info("items#itemprocess found url: &gt;&gt;#{url}&lt;&lt;")
        begin
          linkobj = LinkThumbnailer.generate(url)
        rescue
          # didn't work
        end
        if linkobj
          linkurl = linkobj.url.to_s
          linkimg = linkobj.images.first ? linkobj.images.first.src.to_s : ''
          linktitle = linkobj.title.to_s
          if linkurl != ''
            if linkimg != ''
              @item.embed_code = "<a href=\"#{linkurl}\" target=\"_blank\"><img src=\"#{linkimg}\" width=\"200\" title=\"#{linktitle}\"></a>"
            else
              @item.embed_code = "<a href=\"#{linkurl}\" target=\"_blank\">#{linktitle}</a>"
            end
            @item.oembed_response = {
              'url': linkurl,
              'img': linkimg,
              'title': linktitle,
              'description': linkobj.description,
              'favicon': linkobj.favicon              
            }
          end
        end
      end
    end
  end  
  
  def itempicupload
    #-- Put any uploaded or grabbed picture in the right place
    @participant_id = current_participant.id
    got_file = false
    tempfilepath = "/tmp/#{current_participant.id}_#{Time.now.to_i}"
    `rm -f #{tempfilepath}`    
    logger.info("items#itempicupload tempfilepath:#{tempfilepath}")
    
    if params[:uploadfile_base64] and params[:uploadfile_base64].to_s != ''
      logger.info("items#itempicupload uploaded base64 file")      
      f = File.new(tempfilepath, "wb")      
      f.write(Base64.decode64(params[:uploadfile_base64]))
      f.close
    elsif params[:uploadfile] and params[:uploadfile].original_filename.to_s != ""
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

    `/bin/cp #{tempfilepath} /tmp/itempicupload_last`
      
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
        session[:cur_baseurl] = "https://" + session[:cur_prefix] + "." + ROOTDOMAIN    
      else
        session[:cur_baseurl] = "https://" + BASEDOMAIN    
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
        session[:cur_baseurl] = "https://" + session[:cur_prefix] + "." + ROOTDOMAIN    
      else
        session[:cur_baseurl] = "https://" + BASEDOMAIN    
      end
    end 
  end
  
  def item_params
    params.require(:item).permit(:item_type, :media_type, :group_id, :dialog_id, :period_id, :subject, :short_content, :html_content, :link, :reply_to, :geo_level, :censored, :intra_com, :conversation_id, :intra_conv, :outside_conv_reply, :representing_com)
  end
    
end
