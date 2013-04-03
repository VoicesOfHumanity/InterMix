require 'will_paginate/array'

class GroupsController < ApplicationController

	layout "front"
  before_filter :authenticate_participant!

  def index
    #-- Show an overview of groups this person has access to
    @section = 'groups'
    @groupsin = GroupParticipant.where("participant_id=#{current_participant.id}").select("distinct(group_id),moderator").includes(:group)
    @groupsina = @groupsin.collect{|g| g.group.id if g.group }
    @ismoderator = false
    for group in @groupsin
      @ismoderator = true if group.moderator
    end  
    @groupsopen = Group.where("(openness='open' or openness='open_to_apply')").order("id desc").all
    @groupspublic = Group.where("visibility='public'").order("id desc").all
    update_last_url
  end  
  
  def view
    #-- Presentation for a group one might want to join
    @section = 'groups'
    @gsection = 'info'
    @group = Group.includes(:owner_participant).find(params[:id])
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = (@group_participant and @group_participant.moderator)
    update_last_url
    update_prefix
  end  
  
  def admin
    #-- Overview page for administrators and moderators
    @section = 'groups'
    @gsection = 'admin'
    @group = Group.find(params[:id])
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = (@group_participant and @group_participant.moderator)
    update_last_url
    update_prefix
  end
  
  def moderate
    #-- Main screen for a group moderator
    @section = 'groups'
    @gsection = 'moderate'
    @group = Group.find(params[:id])
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = (@group_participant and @group_participant.moderator)
    update_last_url
    update_prefix
  end  
  
  def new
    #-- Creating a new group
    @section = 'groups'
    @group = Group.new
    @group.owner = current_participant.id
    @group.participants << current_participant
    @metamaps = Metamap.all
    @has_metamaps = {}
    render :action=>'edit'
  end  
  
  def edit
    #-- Editing group information, only for administrators
    @section = 'groups'
    #@group = Group.includes(:group_participants=>:participant).find(params[:id])
    @group = Group.includes(:owner_participant).find(params[:id])
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = (@group_participant and @group_participant.moderator)
    @metamaps = Metamap.all
    @has_metamaps = {}
    for metamap in @group.metamaps
      @has_metamaps[metamap.id] = true
    end
    render :action=>'edit'
    update_prefix
  end  
  
  def update
    @group = Group.find(params[:id])
    @metamaps = Metamap.all
    #logger.info("groups#update metamap parameter: #{params[:metamap]}")
    respond_to do |format|
      if gvalidate and @group.update_attributes(params[:group])
        @group.shortdesc = view_context.strip_tags(@group.shortdesc)[0..123]
        @group.save
        for metamap in Metamap.all
          group_metamap = GroupMetamap.where(:group_id=>@group.id,:metamap_id=>metamap.id).first
          #logger.info("groups#update metamap:#{metamap.id} param:#{params[:metamap][metamap.id.to_s]} group_metamap:#{group_metamap}")
          if params[:metamap] and params[:metamap][metamap.id.to_s] and not group_metamap
            #logger.info("groups#update metamap:#{metamap.id} being set")
            group_metamap = GroupMetamap.new(:group_id=>@group.id,:metamap_id=>metamap.id)
            group_metamap.save!
          elsif (not params[:metamap] or not params[:metamap][metamap.id.to_s]) and group_metamap
            #logger.info("groups#update metamap:#{metamap.id} being deleted")
            group_metamap.destroy
          else
            #logger.info("groups#update metamap:#{metamap.id} no change")
          end  
        end
        format.html { redirect_to :action=>:view, :notice => 'Group was successfully updated.' }
        format.xml  { head :ok }
      else
        @has_metamaps = {}
        for metamap in @group.metamaps
          @has_metamaps[metamap.id] = true
        end
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
    @metamaps = Metamap.all
    respond_to do |format|
      if gvalidate and @group.save
        logger.info("groups_controller#create New group created: #{@group.id}")
        @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
        @group_participant.moderator = true
        @group_participant.active = true
        @group_participant.save
        for metamap in Metamap.all
          group_metamap = GroupMetamap.where(:group_id=>@group.id,:metamap_id=>metamap.id).first
          if params[:metamap] and params[:metamap][metamap.id.to_s] and not group_metamap
            group_metamap = GroupMetamap.new(:group_id=>@group.id,:metamap_id=>metamap.id)
            group_metamap.save!
          elsif (not params[:metamap] or not params[:metamap][metamap.id.to_s]) and group_metamap
            group_metamap.destroy
          end  
        end
        flash[:notice] = 'Group was successfully created.'
        format.html { redirect_to :action=>:view, :id=>@group.id }
      else
        logger.info("groups_controller#create Failed creating new group")
        @has_metamaps = {}
        format.html { render :action=>:edit }
      end
    end
    update_prefix
  end  
  
  def members
    #-- List of members, for either a moderator or other members
    @section = 'groups'
    @group_id = params[:id]
    @group = Group.includes(:group_participants=>:participant).find(params[:id])
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = (@group_participant and @group_participant.moderator)
    update_last_url
    update_prefix
  end  
  
  def invite
    #-- Invite screen
    @section = 'groups'
    @gsection = 'invite'
    @group_id = params[:id]
    @group = Group.includes(:group_participants=>:participant).find(@group_id)
    @messtext = @group.invite_template
    @participant = Participant.includes(:idols).find(current_participant.id)  
    @members = Participant.order("first_name,last_name").all  
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = (@group_participant and @group_participant.moderator)
  end  
  
  def invitedo
    #-- Invite more members
    @section = 'groups'
    @gsection = 'invite'
    @group_id = params[:id]
    @group = Group.includes(:group_participants=>:participant).find(@group_id)
    logger.info("groups#invitedo")  
    flash[:notice] = ''
    flash[:alert] = ''

    @follow_id = params[:follow_id].to_i
    @member_id = params[:member_id].to_i
    @new_text = params[:new_text].to_s
    @messtext = params[:messtext].to_s

    cdata = {}
    cdata['current_participant'] = current_participant
    cdata['group'] = @group if @group
    cdata['logo'] = @group.logo.url if @group.logo.exists?
    cdata['domain'] = @group.shortname.to_s!='' ? "#{@group.shortname}.#{ROOTDOMAIN}" : BASEDOMAIN

    @member_id = @follow_id if @follow_id > 0
    if @member_id > 0
      #-- An existing member
      @recipient = Participant.find_by_id(@member_id)
      @messtext += "<hr><a href=\"http://#{BASEDOMAIN}/participant/#{current_participant.id}/profile?auth_token=#{@recipient.authentication_token}\">#{current_participant.name}</a> has invited you to join the group <a href=\"http://#{BASEDOMAIN}/groups/#{@group.id}/view?auth_token=#{@recipient.authentication_token}\">#{@group.name}</a>"
      if @recipient
        group_participants = GroupParticipant.where("group_id=#{@group.id} and participant_id=#{@recipient.id}").all
        if group_participants.length == 0
          GroupParticipant.create(:group_id=>@group.id, :participant_id=>@recipient.id,:active=>false)
        end
        @recipient.ensure_authentication_token!
        @message = Message.new
        @message.to_participant_id = @recipient.id 
        @message.from_participant_id = current_participant.id
        #@message.subject = "Group invitation"
        @message.subject = "#{current_participant.name} invites you to the #{@group.name} on InterMix"
        
        cdata['item'] = @item
        cdata['recipient'] = @recipient     
        cdata['participant'] = @recipient 

        if @messtext.to_s != ''
          template = Liquid::Template.parse(@messtext)
          html_content = template.render(cdata)
        else  
          html_content = "<p>You have been invited to join the group: #{@group.name}<br/>"
          html_content += "</p>"
        end        
                
        @message.message = html_content
        @message.sendmethod = 'web'
        @message.sent_at = Time.now
        if @message.save
          if @recipient.private_email == 'instant'
            #-- Send as an e-mail. 
            @message.sendmethod = 'email'
            @message.emailit
          end  
          flash[:notice] += "An invitation message was sent to #{@recipient.name}"
        else
          logger.info("groups#invitedo Couldn't save message")  
          flash[:alert] += "There was a problem creating the invitation message for #{@recipient.name}."         
        end
      else
        flash[:alert] += 'Recipient not found'
      end  
      
    else
      #-- Some non-members
      lines = @new_text.split("[\r\n]+")
      #flash[:notice] += "#{lines.length} lines<br>"
      x = 0
      for line in lines do
        email = line.strip

        cdata['email'] = email


        if @messtext.to_s != ''
          template = Liquid::Template.parse(@messtext)
          html_content = template.render(cdata)
        else
          html_content = "<p>You have been invited by #{current_participant.email_address_with_name} to join the group: #{@group.name}<br/>"
          html_content += "Go <a href=\"http://#{@group.shortname}.#{ROOTDOMAIN}/gjoin?group_id=#{@group.id}&email=#{email}\">here</a> to fill in your information and join.<br>"
          html_content += "</p>"            
        end
        
        subject = "#{current_participant.name} invites you to the #{@group.name} on InterMix"

        emailmess = SystemMailer.generic("do-not-reply@intermix.org", email, subject, html_content, cdata)
        logger.info("groups#invitedo delivering email to #{email}")
        begin
          emailmess.deliver
          flash[:notice] += "An invitation message was sent to #{email}"
        rescue
          logger.info("groups#invitedo FAILED delivering email to #{email}")
          flash[:notice] += "Failed to send an invitation to #{email}"
        end

      end
      
    end
    redirect_to :action => :invite
  end

  def import
    #-- Import members
    @section = 'groups'
    @gsection = 'import'
    @group_id = params[:id]
    @group = Group.includes(:group_participants=>:participant).find(@group_id)
    @messtext = flash[:messtext] ? flash[:messtext] : @group.import_template
    @participant = Participant.includes(:idols).find(current_participant.id)  
    @metamaps = Metamap.order("name").all  
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = (@group_participant and @group_participant.moderator)
  end  
  
  def importdo
    #-- Import members directly
    @section = 'groups'
    @gsection = 'import'
    @group_id = params[:id].to_i
    @group = Group.includes(:group_participants=>:participant).find(@group_id)
    logger.info("groups#importdo #{@group_id}")  
    @meta_1 = params[:meta_1].to_i
    @meta_2 = params[:meta_2].to_i
    @meta_3 = params[:meta_3].to_i
    flash[:notice] = ''
    flash[:alert] = ''

    @new_text = params[:new_text].to_s
    @messtext = params[:messtext].to_s

    metamapnames = {}
    metamapids = {}
    metamaprecs = Metamap.all
    for metamap in metamaprecs
      metamapnames[metamap.name.downcase] = metamap.id
      metamapids[metamap.id] = metamap.name
    end

    lines = @new_text.split(/[\r\n]+/)
    flash[:notice] += "#{lines.length} lines<br>"
    x = 0
    for line in lines do
      x += 1
      #next if x == 1
      line = line.force_encoding("ISO-8859-1").encode("UTF-8").strip
      xarr = line.split(';')

      email = xarr[0]
      if xarr.length < 3
        flash[:notice] += "#{email} incorrect number of fields (#{xarr.length}). Need 3+<br>"
        next
      end
      first_name = xarr[1]
      last_name = xarr[2]

      flash[:notice] += "#{email}, #{first_name}, #{last_name}<br>"
      
      if email.to_s == ''
        next
      end

      participant = Participant.find_by_email(email)

      if participant
        flash[:notice] += "- already a member<br>"
        password = "[as entered]"
      else
        participant = Participant.new
        participant.first_name = first_name
        participant.last_name = last_name
        participant.email = email
        password = ''
        3.times do
          conso = 'bcdfghkmnprstvw'[rand(15)]
          vowel = 'aeiouy'[rand(6)]
          password += conso +  vowel
          password += (1+rand(9)).to_s if rand(3) == 2
        end
        participant.password = password
        participant.forum_email = 'never'
        participant.group_email = 'never'
        participant.private_email = 'instant'  
        participant.status = 'active'
        participant.confirmation_token = Digest::MD5.hexdigest(Time.now.to_f.to_s + email)
        if participant.save
          flash[:notice] += "- added as member<br>"
        else
          flash[:notice] += "- problem adding as member<br>"
          next          
        end
      end
      
      #-- Add to group
      added_to_group = false
      group_participants = GroupParticipant.where("group_id=#{@group.id} and participant_id=#{participant.id}").all
      if group_participants.length == 0
        GroupParticipant.create(:group_id=>@group.id, :participant_id=>participant.id,:active=>true)
        flash[:notice] += "- added to the group<br>"
        added_to_group = true
      else
        flash[:notice] += "- already in the group<br>"
      end
      
      #-- Handle metatag fields      
      for pos in [3,4,5,6,7,8,9,10,11,12,13,14,15]
        if not xarr[pos] or xarr[pos].to_s == ''
          next
        end
        metamap_name = ""
        varval = xarr[pos].strip
        if varval.split(':').length > 1
          zarr = varval.split(':')
          metamap_name = zarr[0].strip.downcase
          if metamapnames[metamap_name]
            metamap_id = metamapnames[metamap_name]
          else
            flash[:notice] += "- UNKNOWN META NAME: #{metamap_name}<br>"
            next
          end
          value = zarr[1].strip
        else
          metamap_id = 0
          value = varval
        end
        if metamap_id > 0
        elsif pos == 3
          metamap_id = params[:meta_1].to_i
        elsif pos == 4
          metamap_id = params[:meta_2].to_i
        elsif pos == 5
          metamap_id = params[:meta_3].to_i
        end
        if metamap_name == "" and metamapids[metamap_id]
          metamap_name = metamapids[metamap_id]
        end
        if metamap_id > 0
          metamap = Metamap.find_by_id(metamap_id)
          if not metamap
             flash[:notice] += "- UNKNOWN META ID: #{metamap_id}<br>"
          else
            metamap_nodes = MetamapNode.where(:metamap_id=>metamap_id,:name=>value)
            if metamap_nodes.length > 0
              metamap_node_id = metamap_nodes[0].id
              #flash[:notice] += "- #{metamap_nodes.length} nodes matching metamap_id:#{metamap_id} name:#{value} Choosing:#{metamap_node_id}<br>"
              mnp = MetamapNodeParticipant.where(:metamap_id=>metamap_id,:participant_id=>participant.id).first
              if mnp
                mnp.metamap_node_id = metamap_node_id
                mnp.save
                flash[:notice] += "- updated meta #{metamap_name}: #{value}<br>"
              else
                MetamapNodeParticipant.create(:metamap_id=>metamap_id,:metamap_node_id=>metamap_node_id,:participant_id=>participant.id)
                flash[:notice] += "- added meta #{metamap_name}: #{value}<br>"
              end                  
            else
               flash[:notice] += "- UNKNOWN VALUE for #{metamap_name}: #{value}<br>"
            end
          end
        else
          flash[:notice] +=  "- UNKNOWN: #{value}<br>"
        end  
      end
      
      if @messtext.to_s != '' and added_to_group
        #-- Send an e-mail
        participant.ensure_authentication_token!
        @recipient = participant
        @message = Message.new
        @message.to_participant_id = participant.id 
        @message.from_participant_id = current_participant.id
        @message.subject = "You were added to a group"
        
        cdata = {}
        cdata['item'] = @item
        cdata['recipient'] = participant     
        cdata['participant'] = participant 
        cdata['current_participant'] = current_participant
        cdata['group'] = @group if @group
        cdata['domain'] = @group.shortname.to_s!='' ? "#{@group.shortname}.#{ROOTDOMAIN}" : BASEDOMAIN
        if @group.logo.exists? then
         cdata['logo'] = "#{BASEDOMAIN}#{@group.logo.url}"
        else
          cdata['logo'] = @logo if @logo
        end
        cdata['password'] = password
        
        cdata['template'] = 'system_generic'

        template = Liquid::Template.parse(@messtext)
        html_content = template.render(cdata)
        
        #@messtext += "<hr>username: #{participant.email}<br>password: #{password}"
        @message.message = html_content
        @message.sendmethod = 'web'
        @message.sent_at = Time.now
        @message.group_id = @group.id
        if @message.save
          if participant.private_email == 'instant' and not participant.no_email
            #-- Send as an e-mail. 
            @message.sendmethod = 'email'
            @message.mail_template = 'message_system'
            @message.emailit
          end  
          flash[:notice] += "- message was sent<br>"
        else
          logger.info("groups#importdo Couldn't save message")  
          flash[:alert] += "- problem sending message"         
        end
      end
    end   
    flash[:messtext] = @messtext
    redirect_to :action => :import
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
    update_prefix
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
    @is_moderator = (@group_participant and @group_participant.moderator)
    
    if participant_signed_in? and current_participant.forum_settings
      set = current_participant.forum_settings
    else
      set = {}
    end    
    @sortby = params[:sortby] || set['sortby'] || "items.id desc"
    @perscr = (params[:perscr] || set['perscr'] || 25).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1

    if @sortby[0,5] == 'meta:'
       @sortby = 'items.id desc'
    end
    
    @threads = params[:threads] || set['threads'] || 'flat'
    if @threads == 'flat' or @threads == 'tree' or @threads == 'root'
      @rootonly = true
    end

    if true
      #-- Get the records, while adding up the stats on the fly

      @items, @itemsproc = Item.list_and_results(@group_id,@dialog_id,@period_id,0,@posted_meta,@rated_meta,@rootonly,@sortby,current_participant.id)

    else
      #-- The old way

      @items = Item.scoped
      @items = @items.where("items.group_id = ?", @group_id)    
      if @threads == 'flat' or @threads == 'tree'
        #- Show original message followed by all replies in a flat list
        @items = @items.where("is_first_in_thread=1")
      end
      @items = @items.includes([:group,:participant,:period,{:participant=>{:metamap_node_participants=>:metamap_node}},:item_rating_summary])
      @items = @items.joins("left join ratings on (ratings.item_id=items.id and ratings.participant_id=#{current_participant.id})")
      @items = @items.select("items.*,ratings.participant_id as hasrating,ratings.approval,ratings.interest")
    
      @items = @items.order(@sortby)
      @items = @items.paginate :page=>@page, :per_page => @per_page    
    
    end
    
    @items = @items.paginate :page=>@page, :per_page => @perscr  
        
    @groupsin = GroupParticipant.where("participant_id=#{current_participant.id}").select("distinct(group_id),moderator").includes(:group)

    @dialogsin = DialogParticipant.where("participant_id=#{current_participant.id}").includes(:dialog).all      
    @dialogsin = DialogGroup.where("group_id=#{@group_id}").includes(:dialog).all      

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
  end   

  def period_edit
    @group_id = params[:id].to_i
    @group = Group.find(@group_id)
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = (@group_participant and @group_participant.moderator)
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
    @is_moderator = (@group_participant and @group_participant.moderator)
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

  def dialog_settings
    #-- Show/edit the specifics for the group dialog membership
    @group_id = params[:id].to_i
    @group = Group.find(@group_id)
    @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
    @is_member = @group_participant ? true : false
    @is_moderator = (@group_participant and @group_participant.moderator)
    @dialog_id = params[:dialog_id].to_i
    @dialog = Dialog.find_by_id(@dialog_id)
    @dialog_group = DialogGroup.where("group_id=#{@group_id} and dialog_id=#{@dialog_id}").first   
  end
  
  def dialog_settings_save
    @group_id = params[:id].to_i
    @group = Group.find(@group_id)
    @dialog_group_id = params[:dialog_group_id]
    @dialog_group = DialogGroup.find_by_id(@dialog_group_id)
    @dialog_group.signup_template = params[:dialog_group][:signup_template]
    @dialog_group.confirm_template = params[:dialog_group][:confirm_template]
    @dialog_group.confirm_email_template = params[:dialog_group][:confirm_email_template]
    @dialog_group.save!
    redirect_to :action=>:admin
  end
  
  def apply_dialog
    #-- Apply to be a member of a discussion
    @group_id = params[:id].to_i
    @group = Group.find(@group_id)
    @dialog_id = params[:apply_dialog_id].to_i
    @dialog = Dialog.find_by_id(@dialog_id)
    @dialog_group = DialogGroup.new(:group_id=>@group_id,:dialog_id=>@dialog_id,:active=>false,:apply_status=>'apply',:apply_by=>current_participant.id,:apply_at=>Time.now)
    @dialog_group.save!
    
    for participant in @group.moderators
      #-- Let all moderators of the group know that somebody has filed the application
      @message = Message.new
      @message.subject = "#{@dialog.name} discussion"
      @message.message = "<p>#{current_participant.name} has applied for the group #{@group.name} to join the discussion #{@dialog.name}</p><p>You're receiving this because you're a moderator in #{@group.name}</p>"
      @message.to_participant_id = participant.id
      @message.from_participant_id = 0
      @message.sendmethod = 'web'
      @message.sent_at = Time.now
      if @message.save        
        @message.sendmethod = 'email'
        @message.emailit
      end
    end
    
    #-- Let the discussion administrators know
    @dgroup_id = @dialog.group_id
    @dgroup = Group.find_by_id(@dgroup_id)
    if @dgroup
      for participant in @dgroup.moderators
        #-- Let all moderators of the group owning the discussion know that somebody has filed the application
        @message = Message.new
        @message.subject = "#{@group.name} wants to join #{@dialog.name}"
        @message.message = "<p>#{current_participant.name} has applied for the group #{@group.name} to join the discussion #{@dialog.name}</p><p>Somebody needs to approve the application before the membership becomes active.</p><p>You're receiving this because you're a moderator in #{@dgroup.name} which administers the #{@dialog.name} discussion</p>"
        @message.to_participant_id = participant.id
        @message.from_participant_id = 0
        @message.sendmethod = 'web'
        @message.sent_at = Time.now
        if @message.save        
          @message.sendmethod = 'email'
          @message.emailit
        end
      end
    end
        
    redirect_to :action=>:admin
  end
  
  def add_moderator
    #-- Add a new moderator. Called from admin screen. Must already be a group member
    @group_id = params[:id].to_i
    @group = Group.find(@group_id)
    @participant_id = params[:participant_id].to_i
    if @participant_id > 0
      @group_participant = GroupParticipant.where(:group_id=>@group_id,:participant_id=>@participant_id).first
      if @group_participant
        @group_participant.active = true
        @group_participant.moderator = true
        @group_participant.save!
      end
    end   
    redirect_to :action=>:admin
  end
  
  def group_participant_edit
    #-- Edit a membership in a group, for example to change active or moderator status
    @is_member = true
    @is_moderator = true
    @group_id = params[:id].to_i
    @group = Group.find(@group_id)
    @participant_id = params[:participant_id]
    @group_participant = GroupParticipant.includes(:participant).where(:group_id=>@group_id,:participant_id=>@participant_id).first
  end
  
  def group_participant_save
    #-- Save changes to a group membership
    @group_id = params[:id].to_i
    @group_participant_id = params[:group_participant_id]
    @group_participant = GroupParticipant.find_by_id(@group_participant_id)
    @group_participant.active = params[:group_participant][:active]
    @group_participant.moderator = params[:group_participant][:moderator]
    @group_participant.save!
    flash[:notice] = "Group member settings updated"
    redirect_to :action=>:admin
  end
  
  def get_default
    #-- Return a particular default template, e.g. invite, member, import
    which = params[:which]
    render :partial=>"#{which}_default", :layout=>false
  end

  protected
 
  def update_prefix
    #-- Update the current group, and the prefix and base url
    return if not @group
    #if @is_member
      session[:group_id] = @group.id
      session[:group_name] = @group.name
      session[:group_prefix] = @group.shortname
      session[:group_is_member] = @is_member
    #else
    #  session[:group_id] = 0
    #  session[:group_name] = ''
    #  session[:group_prefix] = ''
    #end
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

end
