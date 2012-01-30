class DialogsController < ApplicationController

	layout "front"
  before_filter :authenticate_participant!

  def index
    #-- Show an overview of dialogs this person has access to
    @section = 'dialogs'
    @gpin = GroupParticipant.where("participant_id=#{current_participant.id}").select("distinct(group_id)").includes(:group).all
    @groupsina = @gpin.collect{|g| g.group.id}
    @dialogsin = []
    ddone = {}
    for gp in @gpin
      gdialogsin = DialogGroup.where("group_id=#{gp.group.id}").includes(:dialog).all
      for gd in gdialogsin
        if not ddone[gd.dialog.id]
          @dialogsin << gd.dialog
          ddone[gd.dialog.id] = true
        end
      end  
    end  
    
    #-- See if they're a moderator of a group, or a hub admin. Only those can add new discussions.
    groupsmodof = GroupParticipant.where("participant_id=#{current_participant.id} and moderator=1").all
    @is_group_moderator = (groupsmodof.length > 0)

    hubadmins = HubAdmin.where("participant_id=#{current_participant.id} and active=1").all
    @is_hub_admin = (hubadmins.length > 0)
    
    @admin4 = DialogAdmin.where("participant_id=?",current_participant.id).collect{|r| r.dialog_id}
    
  end  

  def view
    #-- Presentation for a group one might want to join
    @section = 'dialogs'
    @dsection = 'info'
    @dialog_id = params[:id]
    @dialog = Dialog.includes(:creator).find(@dialog_id)
    dialogadmin = DialogAdmin.where("dialog_id=? and participant_id=?",@dialog_id, current_participant.id)
    @is_admin = (dialogadmin.length > 0)
  end  

  def admin
    #-- Overview page for administrators and moderators
    @section = 'dialogs'
    @dsection = 'admin'
    @group = Group.find(params[:id])
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = @group_participant and @group_participant.moderator
  end

  def new
    #-- Creating a new dialog
    @section = 'dialogs'
    @dsection = 'edit'
    @dialog = Dialog.new
    @dialog.created_by = current_participant.id
    @dialog.visibility = 'public'
    @dialog.openness = 'open'
    @dialog.metamap_vote_own = 'never'
    @dialog.multigroup = true
    @groupsin = GroupParticipant.where("participant_id=#{current_participant.id}").includes(:group).all
    render :action=>'edit'
  end  
  
  def edit
    #-- Editing dialog information, only for administrators
    @section = 'dialogs'
    @dsection = 'edit'
    @dialog_id = params[:id]
    dialogadmin = DialogAdmin.where("dialog_id=? and participant_id=?",@dialog_id, current_participant.id)
    if dialogadmin.length == 0
      redirect_to :action=>:view
    end 
    @is_admin = true
    @groupsin = GroupParticipant.where("participant_id=#{current_participant.id}").includes(:group).all   
    @dialog = Dialog.find_by_id(@dialog_id)
  end  

  def create
    @dialog = Dialog.new(params[:dialog])
    respond_to do |format|
      if dvalidate and @dialog.save
        @dialog.participants << current_participant  # Add as admin
        if @dialog.group_id.to_i > 0
          @group = Group.find(@dialog.group_id)
          @dialog.groups << @group
        end
        logger.info("dialogs_controller#create New dialog created: #{@dialog.id}")
        flash[:notice] = 'Discussion was successfully created.'
        format.html { redirect_to :action=>:view, :id=>@dialog.id }
      else
        logger.info("dialogs_controller#create Failed creating new discussion")
        format.html { render :action=>:edit }
      end
    end
  end  
  
  def update
    @dialog_id = params[:id]
    @dialog = Dialog.find(@dialog_id)
    dialogadmin = DialogAdmin.where("dialog_id=? and participant_id=?",@dialog_id, current_participant.id)
    @is_admin = (dialogadmin.length > 0)
    respond_to do |format|
      if dvalidate and @dialog.update_attributes(params[:dialog])
        format.html { redirect_to :action=>:view, :notice => 'Discussion was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @dialog.errors, :status => :unprocessable_entity }
      end
    end
  end  

  def forum
    #-- Show most recent items that this user is allowed to see
    @group_id,@dialog_id = get_group_dialog_from_subdomain
    @section = 'dialogs'
    @dsection = 'forum'
    @from = 'dialog'
    @dialog_id = params[:id].to_i if not @dialog_id
    @dialog = Dialog.includes(:groups).find_by_id(@dialog_id)
    @groups = @dialog.groups if @dialog and @dialog.groups
    @periods = @dialog.periods if @dialog and @dialog.periods
    
    @groupsin = GroupParticipant.where("participant_id=#{current_participant.id}").includes(:group).all
    dialogadmin = DialogAdmin.where("dialog_id=? and participant_id=?",@dialog_id, current_participant.id)
    @is_admin = (dialogadmin.length > 0)

    if @dialog.max_messages > 0
      @previous_messages = Item.where("posted_by=? and dialog_id=?",current_participant.id,@dialog.id).count
    else
      @previous_messages = 0
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
    #@threads = params[:threads] || set['threads'] || 'flat'
    #@threads = 'flat' if @threads == ''
    @threads = 'flat'

    @items = Item.scoped
    @items = @items.where("items.dialog_id = ?", @dialog_id)    
    if @threads == 'flat' or @threads == 'tree'
      #- Show original message followed by all replies in a flat list
      @items = @items.where("is_first_in_thread=1")
    end
    @items = @items.includes([:dialog,:group,{:participant=>{:metamap_node_participants=>:metamap_node}},:item_rating_summary])

    @show_meta = false
    if @sortby == 'default'
      sortby = 'items.id desc'
      #@items = @items.where("metamap_nodes.metamap_id=4")
    elsif @sortby[0,5] == 'meta:'
      metamap_id = @sortby[5,10].to_i
      sortby = "metamap_nodes.name"
      @items = @items.where("metamap_nodes.metamap_id=#{metamap_id}")
      @show_meta = true
    else
      sortby = @sortby
    end

    @items = @items.joins("left join ratings on (ratings.item_id=items.id and ratings.participant_id=#{current_participant.id})")
    @items = @items.select("items.*,ratings.participant_id as hasrating,ratings.approval as rateapproval,ratings.interest as rateinterest,'' as explanation")
    
    @items = @items.order(sortby)
    if @sortby == 'default'
      @items = Item.custom_item_sort(@items, @page, @perscr, current_participant.id)
    else
      @items = @items.paginate :page=>@page, :per_page => @perscr  
    end
    
    if session[:new_signup].to_i == 1
      @new_signup = true
      session[:new_signup] = 0
    elsif params[:new_signup].to_i == 1
      @new_signup = true
    end

  end   
  
  def period_edit
    @dialog_id = params[:id].to_i
    @dialog = Dialog.find(@dialog_id)
    dialogadmin = DialogAdmin.where("dialog_id=? and participant_id=?",@dialog_id, current_participant.id)
    if dialogadmin.length == 0
      redirect_to :action=>:view
    end 
    @is_admin = true       
    @period_id = params[:period_id].to_i
    if @period_id == 0
      @period = Period.new(:dialog_id=>@dialog_id,:group_dialog=>'dialog')
    else
      @period = Period.find(@period_id)
    end
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
    @period.startdate = params[:period][:startdate]
    @period.endposting = params[:period][:endposting]
    @period.endrating = params[:period][:endrating]
    @period.name = params[:period][:name]
    @period.save!
    redirect_to :action=>:edit
  end
  
  def meta
    #-- Show some stats, according to the metamaps
    @section = 'dialogs'
    @dsection = 'meta'
    @from = 'dialog'
    @dialog_id = params[:id].to_i
    @dialog = Dialog.find(@dialog_id)

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

      #-- Everything posted, with metanode info
      items = Item.where("items.dialog_id=#{@dialog_id}").includes(:participant=>{:metamap_node_participants=>:metamap_node}).includes(:item_rating_summary).where("metamap_node_participants.metamap_id=#{metamap_id}")
      
      #-- Everything rated, with metanode info
      ratings = Rating.where("ratings.dialog_id=#{@dialog_id}").includes(:participant=>{:metamap_node_participants=>:metamap_node}).includes(:item=>:item_rating_summary).where("metamap_node_participants.metamap_id=#{metamap_id}")
      
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

  end

  protected 
  
  def dvalidate
    flash[:alert] = ''
    if params[:dialog][:name].to_s == ''
      flash[:alert] += "The discussion needs a name<br/>"
    elsif params[:dialog][:shortname].to_s == ''
      flash[:alert] += "The discussion needs a short code, used for example in e-mail [subject] lines<br/>"
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

end
