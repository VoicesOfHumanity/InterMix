require 'will_paginate/array'

class CommunitiesController < ApplicationController
 
	layout "front"
  append_before_action :authenticate_user_from_token!, except: [:join, :front, :fronttag]
  append_before_action :authenticate_participant!, except: [:join, :front, :fronttag]
  append_before_action :check_is_admin, except: [:index, :join, :front, :fronttag]
  

  def index
    #-- Show an list of communities
    @section = 'communities'
    
    if not params.has_key?(:which)
      session[:curcomtag] = ''
      session[:curcomid] = 0
    end
    
    if params.has_key?(:sort)
      sort = params[:sort]
      if sort == 'tag'
        @sort = 'tagname'
      elsif sort == 'activity'
        @sort = 'activity'  
      elsif sort == 'id'
        @sort = 'id desc'  
      else
        @sort = 'id desc'
      end     
    else
      @sort = 'activity'
    end

    if params[:which].to_s == 'all' or (current_participant.tag_list.length == 0 and current_participant.status != 'visitor')
      communities = Community.where(is_sub: false).where("context not in ('city','nation')")
      @csection = 'all' 
      @toptitle = "All Communities except Nations and Cities"
    elsif params[:which].to_s == 'human'  or (current_participant.status == 'visitor' and params[:which].to_s == '')
      communities = Community.where(is_sub: false, more: true)
      @csection = 'human' 
    elsif params[:which].to_s == 'un'  
      communities = Community.where(is_sub: false, ungoals: true)
      @csection = 'un' 
    elsif params[:which].to_s == 'cities'  
      @prof_cities = []
      communities = []
      coms = Community.where(context: 'city')
      for com in coms
        if current_participant.city_uniq != '' and com.context_code == current_participant.city_uniq
          com.activity = com.activity_count
          @prof_cities << com
        else
          communities << com
        end
      end
      @csection = 'cities'
    elsif params[:which].to_s == 'nations'  
      @prof_nations = []
      communities = []
      geo1 = ''
      geo2 = ''
      geocountry = Geocountry.find_by_iso(current_participant.country_code)
      geo1 = geocountry.iso3 if geocountry
      if current_participant.country_code2 != ''
        geocountry = Geocountry.find_by_iso(current_participant.country_code2)
        geo2 = geocountry.iso3 if geocountry
      end
      coms = Community.where(is_sub: false, context: 'nation')
      for com in coms
        if com.context_code != '' and (com.context_code == geo1 or com.context_code == geo2)
          com.activity = com.activity_count
          @prof_nations << com
        else
          communities << com
        end
      end
      @csection = 'nations' 
    elsif params[:which].to_s == 'other'  
      communities = Community.where(is_sub: false, major: false, ungoals: false, more: true).where.not(context: 'nation').where.not(context: 'city')
      @csection = 'other'            
    else
      #-- My communities
      comtag_list = ''.dup
      comtags = {}
      for tag in current_participant.tag_list_downcase
        comtags[tag] = true
      end
      if comtags.length > 0
        @comtag_list = comtags.collect{|k, v| "'#{k}'"}.join(',')
        communities = Community.where("tagname in (#{@comtag_list})")
      else
        communities = Community.where("1=0")
      end
      @csection = 'my'      
    end

    if ['id','tag'].include?(sort) or @sort == 'id desc'
      communities = communities.order(@sort)      
    #elsif @sort == 'activity'
    #  logger.info("communities#index pre-sort by tagname in query")
    #  communities = communities.order("tagname")      
    end
    
    @communities = []
    if communities.length > 0
      communities.each do |community|
        #community.members = community.member_count
        community.activity = community.activity_count
        @communities << community
      end
    end
    
    if @communities.length > 0
      if ['id','tag'].include?(sort) or @sort == 'id desc'
      elsif @sort == 'activity'
        @communities.sort! { |a,b| [b.send('activity'),a.send('tagname')] <=> [a.send('activity'),b.send('tagname')] }
      else
        @communities.sort! { |a,b| b.send(@sort) <=> a.send(@sort) }
      end
    end

    @perscr = (params[:perscr] || 20).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1

    #@communities = @communities[0..20]
    @communities = @communities.paginate :page=>@page, :per_page => @perscr 
          
    @sort = sort 
    
  end  

  def show
    #-- The info page
    @community_id = params[:id].to_i
    @community = Community.find(@community_id)
    
    #-- Send them to Conversation forum if the user is a member and the community is a member of just one conversation
    #-- Seems like a bad idea, but OK
    #if @community.conversations.length == 1 and current_participant.tag_list.include?(@community.tagname)
    #  conversation = @community.conversations[0]
    #  redirect_to "/dialogs/#{VOH_DISCUSSION_ID}/slider?conv=#{conversation.shortname}&comtag=#{@community.tagname}"
    #  return
    #end
    #-----
    
    if @community.is_sub
      @parent = Community.find(@community.sub_of)
    end
    
    @subcommunities = Community.where(sub_of: @community_id)
    
    @comtag = @community.tagname   
    session[:curcomtag] = @comtag 
    session[:curcomid] = @community_id 
    @section = 'communities'
    @csection = 'info'
    
    @data = {}
    @data['new_posts'] = @community.activity_count
    @data['num_members'] = @community.member_count
    geo = @community.geo_counts
    logger.info("communities#show geo: #{geo.inspect}")
    @data['nation_count'] = geo[:nations]
    @data['state_count'] = geo[:states]
    @data['metro_count'] = geo[:metros]
    @data['city_count'] = geo[:cities]
    
    #if is_sub
    #  render action: :sub_show
    #else
      render action: :show
    #end
  end
  
  def members
    @community_id = params[:id].to_i
    @community = Community.find(@community_id)
    @comtag = @community.tagname
    session[:curcomtag] = @comtag 
    session[:curcomid] = @community_id 
    @section = 'communities'
    @csection = 'members'

    prepare_members
    
  end
  
  def memlist
    @community_id = params[:id].to_i if not @community_id
    @community = Community.find(@community_id)
    @comtag = @community.tagname
    
    title = ''.dup

    members = Participant.where(status: 'active', no_email: false).tagged_with(@comtag)
    
    geo_level_num = params.has_key?(:geo_level) ? params[:geo_level].to_i : 6
    @geo = GEO_LEVELS[geo_level_num] # {1: 'city', 2: 'county', 3: 'metro', 4: 'state', 5: 'nation', 6: 'planet'}
    if @geo == 'city'
      if current_participant.city.to_s != ''
        members = members.where("participants.city=?",current_participant.city)
        title += "#{current_participant.city}"
      else
        members = members.where("1=0")
        title += "Unknown City"
      end  
    elsif @geo == 'county'  
      if current_participant.admin2uniq.to_s != ''
        members = members.where("participants.admin2uniq=?",current_participant.admin2uniq)
        title += "#{current_participant.geoadmin2.name}"
      else
        members = members.where("1=0")
        title += "Unknown County"
      end  
    elsif @geo == 'metro'
      if current_participant.metro_area_id.to_i > 0
        members = members.where("participants.metro_area_id=?",current_participant.metro_area_id)
        title += "#{current_participant.metro_area.name}"
      else
        members = members.where("1=0")
        title += "Unknown Metro Area"
      end  
    elsif @geo == 'state'  
      if current_participant.admin1uniq.to_s != ''
        members = members.where("participants.admin1uniq=?",current_participant.admin1uniq)
        title += "#{current_participant.geoadmin1.name}"
      else
        members = members.where("1=0")
        title += "Unknown State"
      end  
    elsif @geo == 'nation'
      members = members.where("participants.country_code=?",current_participant.country_code)
      title += "#{current_participant.geocountry.name}"
    elsif @geo == 'planet'
      title += "Planet Earth"  
    #elsif crit[:geo_level] == 'all'
      #title += "All Perspectives"
    end  

    @gender = params.has_key?(:meta_3) ? params[:meta_3].to_i : 0
    @age = params.has_key?(:meta_5) ? params[:meta_5].to_i : 0

    if @gender != 0
      members = members.joins("inner join metamap_node_participants p_mnp_3 on (p_mnp_3.participant_id=participants.id and p_mnp_3.metamap_id=3 and p_mnp_3.metamap_node_id=#{@gender})")   
    end
    if @age != 0
      members = members.joins("inner join metamap_node_participants p_mnp_5 on (p_mnp_5.participant_id=participants.id and p_mnp_5.metamap_id=5 and p_mnp_5.metamap_node_id=#{@age})")   
    end
    if @gender > 0 and @age == 0
      gender = MetamapNode.find_by_id(@gender)
      title += " | #{gender.name_as_group}"
    elsif @gender == 0 and @age > 0
      age = MetamapNode.find_by_id(@age)
      title += " | #{age.name_as_group}"
    elsif @gender > 0 and @age > 0
      gender = MetamapNode.find_by_id(@gender)
      age = MetamapNode.find_by_id(@age)
      xtit = gender.name_as_group
      xtit2 = xtit[0..8] + age.name.capitalize + ' ' + xtit[9..100]
      title += " | #{xtit2}"    
    else
      title += " | Voice of Humanity"
    end
    @title = title
    
    # Get activity in the past month, and sort by it
    @members = []
    for member in members
      member.activity = Item.where(posted_by: member.id).tagged_with(@comtag).where('items.created_at > ?', 31.days.ago).count
      @members << member
    end

    @sort = 'activity'
    @members.sort! { |a,b| b.send(@sort) <=> a.send(@sort) }

    render :partial=>"memlist", :layout=>false
    
  end

  def new
    #-- Add a new forum
    @section = 'communities'
    @csection = 'edit'
    @community = Community.new    
    render action: :edit
  end
  
  def create
    #-- Create a community, the first time
    @section = 'communities'
    @csection = 'edit'
    @community = Community.new(params[:community])
    #@community.tagname.downcase!
    flash.now[:alert] = ''
    if params[:community][:tagname].to_s == ''
      flash.now[:alert] += "The community needs a short name<br/>"
    elsif params[:community][:fullname].to_s == ''
      flash.now[:alert] += "The community needs a long name<br/>"
    end
    if params[:community][:tagname].to_s != ''
      tagname = params[:community][:tagname].strip.gsub(/[^0-9A-za-z_]/,'')
      community = Community.where(tagname: tagname).first
      if community
        flash.now[:alert] += "There's already a @#{tagname} community"
      end
      @community.tagname = tagname
    end
    if flash.now[:alert] != ''  
      render action: :edit
    else  
      @community.save!
      community_admin = CommunityAdmin.create(community_id: @community.id, participant_id: current_participant.id)
      current_participant.tag_list.add(@community.tagname)
      current_participant.save
      redirect_to @community, notice: 'Community was successfully created.'
    end
  end

  def edit
    #-- Edit page
    @community_id = params[:id].to_i
    @community = Community.find(@community_id)
    @comtag = @community.tagname   
    session[:curcomtag] = @comtag 
    session[:curcomid] = @community_id 
    @section = 'communities'
    @csection = 'edit'
    
    @members = Participant.where(status: 'active', no_email: false).tagged_with(@comtag)
    
    @subcommunities = Community.where(sub_of: @community_id)
    
  end
  
  def update
    @community_id = params[:id].to_i
    @community = Community.find(@community_id)
    @community.update_attributes(community_params)
    #@community.tagname.downcase!
    @community.description = sanitizethis(@community.description).strip
    @community.save
    # fix autotags
    if @community.autotags.to_s != ''
      autotags = @community.autotags.gsub('#','')
      newautotags = ''.dup
      tags = autotags.split(/\W+/)
      tagsdone = {}
      for tag in tags
        #tag.downcase!
        if tag.downcase != @community.tagname.downcase and not tagsdone[tag]
          if newautotags != ''
            newautotags += ', '
          end
          newautotags += "##{tag}"
          tagsdone[tag] = true
        end
      end
      @community.autotags = newautotags
      @community.save
    end
    redirect_to :action=>:show, :notice => 'Community was successfully updated.'
  end

  def admins
    #-- Return a list of the admins for this community, as part of the edit page
    @community_id = params[:id].to_i
    @community = Community.includes(:moderators).find(@community_id)
    render :partial=>"adminsedit", :layout=>false
  end  
  
  def admin_add
    #-- Add a community admin
    @community_id = params[:id].to_i
    @community = Community.find_by_id(@community_id)
    @participant_id = params[:participant_id]
    participant = Participant.find_by_id(@participant_id)
    community_admin = CommunityAdmin.where(["community_id = ? and participant_id = ?", @community_id, @participant_id]).first
    if @is_admin and not community_admin
      community_admin = CommunityAdmin.create(:community_id => @community_id, :participant_id => @participant_id)
      if participant
        participant.tag_list.add(@community.tagname)
        participant.save
      end
      # Send an email
      @recipient = participant
      email = participant.email
      @cdata = {}
      @cdata['current_participant'] = current_participant
      @cdata['community'] = @community if @community
      @cdata['community_logo'] = "https://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?
      @cdata['logo'] = "https://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?
      @cdata['email'] = participant.email
      @cdata['comlink'] = "https://#{BASEDOMAIN}/communities/#{@community.id}?auth_token=#{participant.authentication_token}"
      html_content = "<p>You have been added by #{current_participant.email_address_with_name} as a moderator of the community: #{@community.fullname}<br/>"
      html_content += "You will find it <a href=\"#{@cdata['comlink']}\">here</a>.<br>"
      html_content += "</p>"              
      subject = "#{current_participant.name} added you as a moderator"
      emailmess = SystemMailer.template("do-not-reply@intermix.org", email, subject, html_content, @cdata)
      logger.info("communities#admin_add delivering email to #{email}")
      begin
        emailmess.deliver
        #flash[:notice] = "A notice email was sent to #{email}<br>"
      rescue
        logger.info("communities#admin_add FAILED delivering email to #{email}")
        #flash[:notice] = "Failed to send an email to #{email}<br>"
      end
    end
    admins    
  end 
  
  def admin_del 
    #-- Delete a community admin
    @community_id = params[:id].to_i
    participant_ids = params[:participant_ids]
    for participant_id in participant_ids
      participant = Participant.find_by_id(participant_id)
      community_admin = CommunityAdmin.where(["community_id = ? and participant_id = ?", @community_id, participant_id]).first
      if @is_admin and community_admin
        community_admin.destroy
      end
    end
    admins
  end

  def sublist
    #-- Return a list of the sub-communities for this community, as part of the edit page
    @community_id = params[:id].to_i
    @community = Community.find(@community_id)
    @comtag = @community.tagname   
    @subcommunities = Community.where(sub_of: @community_id)
    render :partial=>"sublist", :layout=>false
  end  
  
  def sub_add
    #-- Add a sub-community
    @community_id = params[:id].to_i
    @community = Community.find_by_id(@community_id)
    @tagname = params[:tagname].strip.gsub(/[^0-9A-za-z_]/,'')
    
    scommunity = Community.where(tagname: @tagname).first
    if not @is_admin
      @submessage = "You're not allowed to do that"
    elsif @tagname == ''
      @submessage = "That's not a valid short name"
    elsif scommunity
      @submessage = "There's already a @#{@tagname} community"
    else
      scommunity = Community.create(tagname: @tagname, fullname: @tagname, is_sub: true, sub_of: @community_id)      
      #-- The sub-community should have tags of parents up the line as auto-tags
      tags = []
      tags << @community.tagname
      com = @community
      autotags = @community.autotags.gsub('#','').split(/\W+/)
      for autotag in autotags
        tags << autotag
      end              
      while com.is_sub do
        parent = Community.find_by_id(com.sub_of)  
        tags << parent.tagname
        autotags = parent.autotags.gsub('#','').split(/\W+/)
        for autotag in autotags
          tags << autotag
        end                
        com = parent
      end

      tagtext = ''.dup
      tags.uniq.each do |tag|
        tcom = Community.where(tagname: tag).first
        if tcom
          # only include community tags as autotags
          tagtext += ', ' if tagtext != ''
          tag.gsub!(/[^0-9A-za-z_]/i,'')
          tagtext += "##{tag}"
        end
      end      
      scommunity.autotags = tagtext
      scommunity.save
    end

    sublist    
  end 
  
  def sub_del 
    #-- Remove a sub-community
    @community_id = params[:id].to_i
    sub_ids = params[:sub_ids]
    for sub_id in sub_ids
      scommunity = Community.where(id: sub_id, is_sub: true, sub_of: @community_id).first
      if @is_admin and scommunity
        scommunity.destroy
      else  
        @submessage = "You're not allowed to do that"
      end
    end
    sublist
  end
  

  def member_add
    #-- Add a member. I.e. join them to that community
    @community_id = params[:id].to_i
    @community = Community.find_by_id(@community_id)
    @participant_id = params[:participant_id]
    participant = Participant.find_by_id(@participant_id)    
    if participant
      participant.tag_list.add(@community.tagname)
      participant.save
    end    
    memlist   
  end 
  
  def member_del 
    #-- Delete a member
    @community_id = params[:id].to_i
    participant_ids = params[:participant_ids]
    for participant_id in participant_ids
      participant = Participant.find_by_id(participant_id)      
      if participant
        participant.tag_list.remove(comtag)
        participant.save
      end      
    end
    memlist
  end
  
  def import_member
    #-- Add a user who isn't member as member of this community
    prepare_members
    @email = params[:email].to_s
    @first_name = params[:first_name].to_s
    @last_name = params[:last_name].to_s
    @gender = params[:gender].to_i
    @age = params[:age].to_i
    #@nation = params[:nation].to_i
    @country_code = params[:country_code].to_s
    @admin1uniq = params[:admin1uniq].to_s
    @admin2uniq = params[:admin2uniq].to_s
    @city = params[:city].to_s
    @country_code2 = params[:country_code2].to_s    
    flash[:notice] = ''
    flash.now[:alert] = ""
    if @email == ""
      flash.now[:alert] += 'email missing<br>'
    end
    if @first_name == '' and @last_name == ''
      flash.now[:alert] += 'name missing<br>'      
    end
    if @gender == 0
      flash.now[:alert] += 'gender missing<br>'
    end
    if @age == 0
      flash.now[:alert] += 'age missing<br>'
    end
    if @country_code == ''
      flash.now[:alert] += 'country missing<br>'
    end
    if flash.now[:alert] != ''
      #redirect_to action: :members
      render action: :members
      return
    end
      
    email = @email  
    participant = Participant.find_by_email(@email)
    if participant
      # 'unconfirmed','active','inactive','never-contact','disallowed'
      if participant.status == 'active'
        flash.now[:alert] += "#{@email} is already a member<br>"
      elsif participant.status == 'disallowed' or participant.status == 'never-contact' or participant.status == 'blocked'
        flash.now[:alert] += "#{@email} is already a member, but blocked<br>"
      else    
        flash.now[:alert] += "#{@email} is already a member, but unconfirmed<br>"
      end
    end
    if flash.now[:alert] != ''
      #redirect_to action: :members
      render action: :members
      return
    end

    participant = Participant.new
    participant.first_name = @first_name
    participant.last_name = @last_name
    participant.email = @email
    participant.city = @city
    #if @nation == 395
    #  participant.country_code = 'US'
    #  participant.country_name = 'United States'
    #end
    participant.country_code = @country_code
    participant.country_code2 = @country_code2
    participant.admin1uniq = @admin1uniq
    participant.admin2uniq = @admin2uniq
    password = ''.dup
    3.times do
      conso = 'bcdfghkmnprstvw'[rand(15)]
      vowel = 'aeiouy'[rand(6)]
      password += conso +  vowel
      password += (1+rand(9)).to_s if rand(3) == 2
    end
    participant.password = password
    participant.forum_email = 'daily'
    participant.group_email = 'daily'
    participant.private_email = 'instant'  
    participant.status = 'active'
    participant.confirmation_token = Digest::MD5.hexdigest(Time.now.to_f.to_s + participant.email)
    participant.ensure_authentication_token!
    if participant.save
      flash[:notice] += "#{@email} added as member<br>"
      MetamapNodeParticipant.create(:metamap_id=>3,:metamap_node_id=>@gender,:participant_id=>participant.id)
      MetamapNodeParticipant.create(:metamap_id=>5,:metamap_node_id=>@age,:participant_id=>participant.id)
      MetamapNodeParticipant.create(:metamap_id=>4,:metamap_node_id=>@nation,:participant_id=>participant.id)
      # Add them to the community
      participant.tag_list.add(@community.tagname)
      participant.save
      # Send an email
      @recipient = participant
      email = participant.email
      @cdata = {}
      @cdata['current_participant'] = current_participant
      @cdata['recipient'] = @recipient
      @cdata['community'] = @community if @community
      @cdata['community_logo'] = "https://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?
      @cdata['logo'] = "https://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?
      @cdata['email'] = participant.email
      @cdata['comlink'] = "https://#{BASEDOMAIN}/communities/#{@community.id}?auth_token=#{participant.authentication_token}"
      html_content = "<p>You have been added by #{current_participant.email_address_with_name} as a member of the community: #{@community.fullname}<br/>"
      html_content += "You will find it <a href=\"#{@cdata['comlink']}\">here</a>.</p>"      
      html_content += "<p>username: #{participant.email}<br/>"
      html_content += "password: #{password}</p>"
      subject = "Welcome to Voices of Humanity"
      emailmess = SystemMailer.template("do-not-reply@intermix.org", email, subject, html_content, @cdata)
      logger.info("communities#import_member delivering email to #{email}")
      begin
        emailmess.deliver
        #flash[:notice] = "A notice email was sent to #{email}<br>"
      rescue
        logger.info("communities#admin_add FAILED delivering email to #{email}")
        #flash[:notice] = "Failed to send an email to #{email}<br>"
      end
      @email = ''
      @first_name = ''
      @last_name = ''
      @gender = 0
      @age = 0
      @nation = 0
      @city = ''
    else
      flash.now[:alert] += "problem adding #{email} as member<br>"
      render action: :members
      return
    end

    redirect_to action: :members
  end
  
  def invite
    #-- Invite screen
    @section = 'communities'
    @csection = 'invite'
    @community_id = params[:id].to_i
    @community = Community.find_by_id(@community_id)
    #@xpreview = get_preview_template(@community_id, 'invite')
    @preview = "<b>test</b>"
  end  
  
  def invitedo
    #-- Invite more members
    @section = 'communities'
    @csection = 'invite'
    @community_id = params[:id].to_i
    @community = Community.find_by_id(@community_id)
    logger.info("communities#invitedo")  
    flash[:notice] = ''
    flash[:alert] = ''

    @new_text = params[:new_text].to_s
    @messtext = params[:messtext].to_s
    if @community.invite_template.to_s != ''
      @messtext += "<br><hr style=\"clear:both;\">\n" if @messtext != ''
      @messtext += @community.invite_template
    else       
      @messtext += render_to_string :partial=>"invite_default", :layout=>false
    end  

    @cdata = {}
    @cdata['current_participant'] = current_participant
    @cdata['community'] = @community if @community
    @cdata['community_logo'] = "https://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?
    @cdata['logo'] = "https://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?

    if not ( @is_admin )
      flash[:alert] += "You're not allowed to invite new members<br>"
    else
      #-- Some non-members, supposedly. But catch if some of them already are members.
      lines = @new_text.split(/[\r\n]+/)
      flash[:notice] += "#{lines.length} lines<br>"
      x = 0
      for line in lines do
        email = line.strip

        @recipient = Participant.find_by_email(email)
        #if @recipient
        #  flash[:alert] += "\"#{email}\" is already a Voices of Humanity member<br>"  
        if not email =~ /^[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,4}$/
          flash[:alert] += "\"#{email}\" doesn't look like a valid e-mail address<br>"  
        else
          
          #@cdata['joinlink'] = "https://#{BASEDOMAIN}/fbjoinlink?comtag=#{@community.tagname}&amp;joincom=1&amp;email=#{email}"
          
          if @recipient
            # They already have an account, send a link that logs them in, joins them, and sends them to the forum
            if @community.conversations.length == 1
              # If the community is a member of just one conversation, go there
              @conversation = @community.conversations[0]
              @cdata['joinlink'] = "https://#{BASEDOMAIN}/dialogs/#{VOH_DISCUSSION_ID}/slider?conv=#{@conversation.shortname}&amp;comtag=#{@community.tagname}&amp;joincom=1&amp;auth_token=#{@recipient.authentication_token}"            
            else
              @cdata['joinlink'] = "https://#{BASEDOMAIN}/dialogs/#{VOH_DISCUSSION_ID}/slider?comtag=#{@community.tagname}&amp;joincom=1&amp;auth_token=#{@recipient.authentication_token}"
            end
          else
            @cdata['joinlink'] = "https://#{BASEDOMAIN}/#{@community.tagname}?joincom=1&amp;email=#{CGI.escape(email)}"            
          end
          
          @cdata['email'] = email

          if @messtext.to_s != ''
            template = Liquid::Template.parse(@messtext)
            html_content = template.render(@cdata)
          else
            html_content = "<p>You have been invited by #{current_participant.email_address_with_name} to join the community: #{@community.name}<br/>"
            html_content += "Go <a href=\"#{@cdata['joinlink']}\">here</a> to join.<br>"
            html_content += "</p>"            
          end
        
          subject = "#{current_participant.name} invites you to the \"#{@community.name}\" community on Voices of Humanity"

          emailmess = SystemMailer.template("do-not-reply@intermix.org", email, subject, html_content, @cdata)

          logger.info("communities#invitedo delivering email to #{email}")
          begin
            emailmess.deliver
            flash[:notice] += "An invitation message was sent to #{email}<br>"
          rescue
            logger.info("communities#invitedo FAILED delivering email to #{email}")
            flash[:notice] += "Failed to send an invitation to #{email}<br>"
          end
        end

      end
      
    end
    redirect_to :action => :invite
  end

  def test_template
    #-- Show a template with the liquid macros filled in
    which = params[:which]
    @community_id = params[:id].to_i
    @community = Community.find_by_id(@community_id)
    @logo = @community.logo.exists? ? "https://#{BASEDOMAIN}#{@community.logo.url}" : "" 
    @participant = current_participant
    @email = @participant.email
    @name = @participant.name
    @countries = Geocountry.order(:name).select([:name,:iso])
    
    cdata = {}
    cdata['community'] = @community
    cdata['community_logo'] = @logo
    cdata['participant'] = @participant
    cdata['current_participant'] = @current_participant
    cdata['recipient'] = @participant
    cdata['password'] = '[#@$#$%$^]'
    cdata['confirmlink'] = "https://#{@domain}/front/confirm?code=#{@participant.confirmation_token}&group_id=#{@group_id}"
    cdata['logo'] = @logo
    cdata['message'] = '[Custom message]'    
    cdata['subject'] = '[Subject line]'
      
    if @community.send("#{which}_template").to_s != ""
      template_content = render_to_string(plain: @community.send("#{which}_template"), layout: false)
    else
      template_content = render_to_string(:partial=>"#{which}_default",:layout=>false)
    end      
    template = Liquid::Template.parse(template_content)
    render html: template.render(cdata).html_safe, layout: false
  end

  def get_default
    #-- Return a particular default template, e.g. invite, member, import
    which = params[:which]
    render :partial=>"#{which}_default", :layout=>false
  end
  
  def front
    #-- Show the public front page
    #-- http://voh.intermix.cr8.com/communities/30/front
    @community_id = params[:id].to_i
    @community = Community.find_by_id(@community_id)    
    if participant_signed_in?
      redirect_to "/communities/#{@community_id}"
      return
    end
    session[:sawfront] = 'yes'
    session[:previous_comtag] = @community.tagname
    @dialog_id = VOH_DISCUSSION_ID
    @cdata = {}
    @cdata['community'] = @community
    @cdata['community_logo'] = "https://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?
    @cdata['logo'] = "https://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?
    if @community.front_template.to_s.strip != ''
      desc = Liquid::Template.parse(@community.front_template).render(@cdata)
    else   
      tcontent = render_to_string :partial=>"communities/front_default", :layout=>false
      desc = Liquid::Template.parse(tcontent).render(@cdata)
    end
    @content = "<div>#{desc}</div>"        
  end

  def fronttag
    #-- Show the public front page
    #-- http://voh.intermix.cr8.com/nuclear_disarm
    tagname = params[:tagname].to_s
    @community = Community.find_by_tagname(tagname)
    if not @community
      # If it doesn't exist, maybe it is a conversation?
      @conversation = Conversation.find_by_shortname(tagname)
      if @conversation
        redirect_to "/conversation/#{tagname}"
        return
      else
        redirect_to "/"
        return
      end
    end    
    session[:sawfront] = 'yes'
    session[:previous_comtag] = tagname
    @comtag = tagname
    @community_id = @community.id        
    if participant_signed_in?
      if @community.conversations.length == 1
        conversation = @community.conversations[0]
        redirect_to "/dialogs/#{VOH_DISCUSSION_ID}/slider?conv=#{conversation.shortname}&comtag=#{@community.tagname}"
        return
      else
        redirect_to "/communities/#{@community_id}"
        return
      end
    end
    @dialog_id = VOH_DISCUSSION_ID
    @cdata = {}
    @cdata['community'] = @community
    @cdata['community_logo'] = "https://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?
    @cdata['logo'] = "https://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?
    if @community.front_template.to_s.strip != ''
      desc = Liquid::Template.parse(@community.front_template).render(@cdata)
    else   
      tcontent = render_to_string :partial=>"communities/front_default", :layout=>false
      desc = Liquid::Template.parse(tcontent).render(@cdata)
    end
    @content = "<div>#{desc}</div>"    
    session[:comtag] = @comtag
    session[:joincom] = 1
    render action: :front    
  end

  def join
    #-- Public form for joining and joining the community NB: Oops, started, but not finished
    @community_id = params[:id].to_i
    @community = Community.find_by_id(@community_id)    
    if not @community
      flash[:alert] = "Community not found"
      redirect_to "//#{BASEDOMAIN}/join"
      return  
    elsif @community and current_participant and participant_signed_in?
      flash[:alert] = "You are already logged in"
      redirect_to "//#{BASEDOMAIN}/communities/#{@community.id}"
      return
    end
    #prepare_gjoin    
    render action: :join, :layout => 'front'
  end  

  protected

  def community_params
    params.require(:community).permit(:fullname, :description, :logo, :twitter_post, :twitter_username, :twitter_oauth_token, :twitter_oauth_secret, :twitter_hash_tag, :tweet_approval_min, :tweet_what, :front_template, :member_template, :invite_template, :import_template, :signup_template, :confirm_template, :confirm_email_template, :confirm_welcome_template, :autotags, :active)
  end
  
  def check_is_admin
    @community_id = params[:id].to_i
    @is_admin = false
    @is_super = false
    @is_moderator = false
    if current_participant.sysadmin
      @is_admin = true
      @is_super = true
    else
      admin = CommunityAdmin.where(["community_id = ? and participant_id = ?", @community_id, current_participant.id]).first
      if admin
        @is_admin = true
        @is_moderator = true
      end
    end
  end
  
  def prepare_members
    if not @community
      @community_id = params[:id].to_i
      @community = Community.find(@community_id)
      @comtag = @community.tagname
    end
    
    if @community.is_sub
      @parent = Community.find(@community.sub_of)
    end

    @section = 'communities'
    @csection = 'members'

    @participants = Participant.where(status: 'active', no_email: false).order("last_name,first_name,id")     
    
    @geo_levels = [
      [6,'Planet&nbsp;Earth'],
      [5,'My&nbsp;Nation'],
      [4,'State/Province'],
      [3,'My&nbsp;Metro&nbsp;region'],
      [2,'My&nbsp;County'],
      [1,'My&nbsp;City/Town']
    ]
    @geo_level = 6 if not @geo_level
    
    @countries = Geocountry.order(:name).select([:name,:iso])
    
  end

  def get_preview_template(community_id, which)
    #-- Just to produce a partially filled in template preview
    @community_id = community_id
    @community = Community.find_by_id(@community_id)
    @logo = @community.logo.exists? ? "https://#{BASEDOMAIN}#{@community.logo.url}" : "" 
    @participant = current_participant
    @email = @participant.email
    @name = @participant.name
    @countries = Geocountry.order(:name).select([:name,:iso])
    
    cdata = {}
    cdata['community'] = @community
    cdata['community_logo'] = @logo
    cdata['participant'] = @participant
    cdata['current_participant'] = @current_participant
    cdata['recipient'] = @participant
    cdata['password'] = '[#@$#$%$^]'
    cdata['confirmlink'] = "https://#{@domain}/front/confirm?code=#{@participant.confirmation_token}&group_id=#{@group_id}"
    cdata['logo'] = @logo
    cdata['message'] = '[Custom message]'    
    cdata['subject'] = '[Subject line]'
      
    if @community.send("#{which}_template").to_s != ""
      template_content = render_to_string(plain: @community.send("#{which}_template"), layout: false)
    else
      template_content = render_to_string(:partial=>"#{which}_default",:layout=>false)
    end      
    preview_html = Liquid::Template.parse(template_content).render(cdata)
    return(preview_html)
  end

end