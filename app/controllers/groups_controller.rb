class GroupsController < ApplicationController

	layout "front"
  before_filter :authenticate_participant!

  def index
    #-- Show an overview of groups this person has access to
    @section = 'groups'
    @groupsin = GroupParticipant.where("participant_id=#{current_participant.id}").includes(:group).all
    @groupsina = @groupsin.collect{|g| g.group.id}
    @ismoderator = false
    for group in @groupsin
      @ismoderator = true if group.moderator
    end  
    @groupsopen = Group.where("(openness='open' or openness='open_to_apply')").order("id desc").all
    update_last_url
  end  
  
  def view
    #-- Presentation for a group one might want to join
    @section = 'groups'
    @gsection = 'info'
    @group = Group.includes(:owner_participant).find(params[:id])
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = @group_participant and @group_participant.moderator
    update_last_url
  end  
  
  def admin
    #-- Overview page for administrators and moderators
    @section = 'groups'
    @gsection = 'admin'
    @group = Group.find(params[:id])
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = @group_participant and @group_participant.moderator
    update_last_url
  end
  
  def moderate
    #-- Main screen for a group moderator
    @section = 'groups'
    @gsection = 'moderate'
    @group = Group.find(params[:id])
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = @group_participant and @group_participant.moderator
    update_last_url
  end  
  
  def new
    #-- Creating a new group
    @section = 'groups'
    @group = Group.new
    @group.owner = current_participant.id
    @group.participants << current_participant
    render :action=>'edit'
  end  
  
  def edit
    #-- Editing group information, only for administrators
    @section = 'groups'
    @group = Group.includes(:group_participants=>:participant).find(params[:id])
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = @group_participant and @group_participant.moderator
  end  
  
  def update
    @group = Group.find(params[:id])
    respond_to do |format|
      if gvalidate and @group.update_attributes(params[:group])
        format.html { redirect_to :action=>:view, :notice => 'Group was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end  
  
  def gvalidate
    flash[:alert] = ''
    if params[:group][:name].to_s == ''
      flash[:alert] += "The group needs a name<br/>"
    elsif params[:group][:shortname].to_s == ''
      flash[:alert] += "The group needs a short name, used for example in e-mail [subject] lines<br/>"
    end
    if params[:group][:owner].to_i == 0
      flash[:alert] += "Who is the owner of the group? Most likely you.<br/>"
    end  
    if params[:group][:openness].to_s == ''
      flash[:alert] += "Please choose a membership setting<br/>"
    end
    if params[:group][:visibility].to_s == ''
      flash[:alert] += "Please set the visibility<br/>"
    end
    logger.info("groups_controller#gvalidate failed: #{flash[:alert]}") if flash[:alert] != ''
    flash[:alert] == ''
  end  
  
  def create
    @group = Group.new(params[:group])
    @group.participants << current_participant
    respond_to do |format|
      if gvalidate and @group.save
        logger.info("groups_controller#create New group created: #{@group.id}")
        flash[:notice] = 'Group was successfully created.'
        format.html { redirect_to :action=>:view, :id=>@group.id }
      else
        logger.info("groups_controller#create Failed creating new group")
        format.html { render :action=>:edit }
      end
    end
  end  
  
  def members
    #-- List of members, for either a moderator or other members
    @section = 'groups'
    @group_id = params[:id]
    @group = Group.includes(:group_participants=>:participant).find(params[:id])
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = @group_participant and @group_participant.moderator
    update_last_url
  end  
  
  def invite
    #-- Invite screen
    @section = 'groups'
    @gsection = 'invite'
    @group_id = params[:id]
    @group = Group.includes(:group_participants=>:participant).find(@group_id)
    @participant = Participant.includes(:idols).find(current_participant.id)  
    @members = Participant.order("first_name,last_name").all  
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = @group_participant and @group_participant.moderator
  end  
  
  def invitedo
    #-- Invite more members
    @section = 'groups'
    @gsection = 'invite'
    @group_id = params[:id]
    @group = Group.includes(:group_participants=>:participant).find(@group_id)
    logger.info("groups#invitedo")  

    @follow_id = params[:follow_id].to_i
    @member_id = params[:member_id].to_i
    @new_text = params[:new_text].to_s

    @member_id = @follow_id if @follow_id > 0
    if @member_id > 0
      @recipient = Participant.find_by_id(@member_id)
      messtext = "<a href=\"http://#{BASEDOMAIN}/participants/#{current_participant.id}/profile\">#{current_participant.name}</a> has invited you to join the group <a href=\"http://#{BASEDOMAIN}/groups/#{@group.id}/view\">#{@group.name}</a>"
      if @recipient
        group_participants = GroupParticipant.where("group_id=#{@group.id} and participant_id=#{@recipient.id}").all
        if group_participants.length == 0
          GroupParticipant.create(:group_id=>@group.id, :participant_id=>@recipient.id,:active=>false)
        end
        @message = Message.new
        @message.to_participant_id = @recipient.id 
        @message.from_participant_id = current_participant.id
        @message.subject = "Group invitation"
        @message.message = messtext
        @message.sendmethod = 'web'
        @message.sent_at = Time.now
        if @message.save
          if @recipient.private_email == 'instant'
            #-- Send as an e-mail. 
            @message.sendmethod = 'email'
            @message.emailit
          end  
          flash[:notice] = "An invitation message was sent to #{@recipient.name}"
        else
          logger.info("groups#invitedo Couldn't save message")  
          flash[:alert] = "There was a problem creating the invitation message for #{@recipient.name}."         
        end
      else
        flash[:alert] = 'Recipient not found'
      end  
    end

    redirect_to :action => :invite

  end
  
  def join
    #-- Join a group
    @group_id = params[:id].to_i
    @group = Group.find(@group_id)
    if @group.openness == 'open'
      @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group_id,current_participant.id).find(:first)
      if @group_participant
        flash[:notice] = 'You are already a member of this group'
      else  
        @group_participant = GroupParticipant.new(:moderator => false, :active => true)
        @group_participant.active = true
        @group_participant.group_id = @group.id
        @group_participant.participant_id = current_participant.id
        @group_participant.save
        flash[:notice] = 'You have joined this group'
      end
    else
      flash[:notice] = 'This group is not open to join'
    end
    redirect_to :action => :view 
  end
  
  def unjoin
    #-- Leave a group
    @group_id = params[:id].to_i
    @group = Group.find(@group_id)
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group_id,current_participant.id).find(:first)
    if @group_participant
      @group_participant.destroy
      flash[:notice] = "You have now left this group"     
    else
      flash[:notice] = "You don't seem to be a member of this group"     
    end  
    redirect_to :action => :view 
  end   
  
  def forum
    #-- Show most recent items that this user is allowed to see
    @section = 'groups'
    @gsection = 'forum'
    @from = 'group'
    @group_id = params[:id].to_i
    @group = Group.includes(:owner_participant).find(@group_id)
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = @group_participant and @group_participant.moderator
    
    if participant_signed_in? and current_participant.forum_settings
      set = current_participant.forum_settings
    else
      set = {}
    end    
    @sortby = params[:sortby] || set['sortby'] || "items.id desc"
    @perscr = (params[:perscr] || set['perscr'] || 25).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    @threads = params[:threads] || set['threads'] || ''

    if @sortby[0,5] == 'meta:'
       @sortby = 'items.id desc'
    end

    @items = Item.scoped
    @items = @items.where("items.group_id = ?", @group_id)    
    if @threads == 'flat' or @threads == 'tree'
      #- Show original message followed by all replies in a flat list
      @items = @items.where("is_first_in_thread=1")
    end
    @items = @items.includes([:group,:participant,:item_rating_summary])
    @items = @items.joins("left join ratings on (ratings.item_id=items.id and ratings.participant_id=#{current_participant.id})")
    @items = @items.select("items.*,ratings.participant_id as hasrating,ratings.approval,ratings.interest")
    
    @items = @items.order(@sortby)
    @items = @items.paginate :page=>@page, :per_page => @per_page    
    @groupsin = GroupParticipant.where("participant_id=#{current_participant.id}").includes(:group).all      

    @dialogsin = DialogParticipant.where("participant_id=#{current_participant.id}").includes(:dialog).all      

    @dialogsin = DialogGroup.where("group_id=#{@group_id}").includes(:dialog).all      

    update_last_url
  end   

  def period_edit
    @group_id = params[:id].to_i
    @group = Group.find(@group_id)
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = @group_participant and @group_participant.moderator
    @period_id = params[:period_id].to_i
    if @period_id == 0
      @period = Period.new(:group_id=>@group_id,:group_dialog=>'group')
    else
      @period = Period.find(@period_id)
    end
  end
  
  def period_save
    @group_id = params[:id].to_i
    @group = Group.find(@group_id)
    @period_id = params[:period_id].to_i    
    if @period_id > 0
      @period = Period.find(@period_id)
    else
      @period = Period.new()
      @period.group_id = @group_id
      @period.group_dialog = 'group'
    end  
    @period.startdate = params[:period][:startdate]
    @period.enddate = params[:period][:enddate]
    @period.name = params[:period][:name]
    @period.save!
    redirect_to :action=>:admin
  end
  
  def subtag_edit
    @group_id = params[:id].to_i
    @group = Group.find(@group_id)
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = @group_participant and @group_participant.moderator
    @group_subtag_id = params[:group_subtag_id].to_i
    if @group_subtag_id == 0
      @group_subtag = GroupSubtag.new(:group_id=>@group_id)
    else
      @group_subtag = GroupSubtag.find(@group_subtag_id)
    end
  end
  
  def subtag_save
    @group_id = params[:id].to_i
    @group = Group.find(@group_id)
    @group_subtag_id = params[:group_subtag_id].to_i    
    if @group_subtag_id > 0
      @group_subtag = GroupSubtag.find(@group_subtag_id)
    else
      @group_subtag = GroupSubtag.new()
      @group_subtag.group_id = @group_id
    end  
    @group_subtag.tag = params[:group_subtag][:tag]
    @group_subtag.save!
    redirect_to :action=>:admin
  end
  

end
