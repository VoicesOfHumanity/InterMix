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

    if params[:which].to_s == 'all' or current_participant.tag_list.length == 0
      communities = Community.all
      @csection = 'all'      
    else
      comtag_list = ''
      comtags = {}
      for tag in current_participant.tag_list
        comtags[tag] = true
      end
      @comtag_list = comtags.collect{|k, v| "'#{k}'"}.join(',')
      communities = Community.where("tagname in (#{@comtag_list})")
      @csection = 'my'      
    end

    if ['id','tag'].include?(sort) or @sort == 'id desc'
      communities = communities.order(@sort)      
    end
    
    @communities = []
    communities.each do |community|
      #community.members = community.member_count
      community.activity = community.activity_count
      @communities << community
    end
    
    if ['id','tag'].include?(sort) or @sort == 'id desc'
    else
      @communities.sort! { |a,b| b.send(@sort) <=> a.send(@sort) }
    end
       
    @sort = sort 
    
  end  

  def show
    #-- The info page
    @community_id = params[:id].to_i
    @community = Community.find(@community_id)
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
  end
  
  def members
    @community_id = params[:id].to_i
    @community = Community.find(@community_id)
    @comtag = @community.tagname
    session[:curcomtag] = @comtag 
    session[:curcomid] = @community_id 
    @section = 'communities'
    @csection = 'members'

    @participants = Participant.where(status: 'active')     
    
    @geo_levels = [
      [5,'Planet&nbsp;Earth'],
      [4,'My&nbsp;Nation'],
      [3,'State/Province'],
      [2,'My&nbsp;Metro&nbsp;region'],
      [1,'My&nbsp;City/Town']
    ]  
  end
  
  def memlist
    @community_id = params[:id].to_i
    @community = Community.find(@community_id)
    @comtag = @community.tagname

    members = Participant.where(status: 'active').tagged_with(@comtag)
    
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

  def edit
    #-- Edit page
    @community_id = params[:id].to_i
    @community = Community.find(@community_id)
    @comtag = @community.tagname   
    session[:curcomtag] = @comtag 
    session[:curcomid] = @community_id 
    @section = 'communities'
    @csection = 'edit'
    
    @participants = Participant.where(status: 'active')
    
  end
  
  def update
    @community_id = params[:id].to_i
    @community = Community.find(@community_id)
    @community.update_attributes(community_params)
    @community.save
    # fix autotags
    if @community.autotags.to_s != ''
      autotags = @community.autotags.gsub('#','')
      newautotags = ''
      tags = autotags.split(/\W+/)
      tagsdone = {}
      for tag in tags
        tag.downcase!
        if tag != @community.tagname.downcase and not tagsdone[tag]
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
      @cdata['community_logo'] = "http://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?
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
    @section = 'communities'
    @csection = 'members'
    @participants = Participant.where(status: 'active')       
    @community_id = params[:id].to_i
    @community = Community.find_by_id(@community_id)
    @email = params[:email].to_s
    @first_name = params[:first_name].to_s
    @last_name = params[:last_name].to_s
    @gender = params[:gender].to_i
    @age = params[:age].to_i
    @nation = params[:nation].to_i
    @city = params[:city].to_s
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
    if @nation == 0
      flash.now[:alert] += 'nation missing<br>'
    end
    if @city == ""
      flash.now[:alert] += 'city missing<br>'
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
    if @nation == 395
      participant.country_code = 'US'
      participant.country_name = 'United States'
    end
    password = ''
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
      @cdata['community'] = @community if @community
      @cdata['community_logo'] = "http://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?
      @cdata['logo'] = "https://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?
      @cdata['email'] = participant.email
      @cdata['comlink'] = "https://#{BASEDOMAIN}/communities/#{@community.id}?auth_token=#{participant.authentication_token}"
      html_content = "<p>You have been added by #{current_participant.email_address_with_name} as a member of the community: #{@community.fullname}<br/>"
      html_content += "You will find it <a href=\"#{@cdata['comlink']}\">here</a>.</p>"      
      html_content += "<p>username: #{participant.email}<br/>"
      html_content += "password: #{password}</p>"
      subject = "#{current_participant.name} added you to the community #{@community.fullname}"
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
      exit
    end

    redirect_to action: :members
  end
  
  def invite
    #-- Invite screen
    @section = 'communities'
    @csection = 'invite'
    @community_id = params[:id].to_i
    @community = Community.find_by_id(@community_id)
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
    @cdata['community_logo'] = "http://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?
    @cdata['logo'] = "http://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?

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
        if @recipient
          flash[:alert] += "\"#{email}\" is already a Voices of Humanity member<br>"  
        elsif not email =~ /^[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,4}$/
          flash[:alert] += "\"#{email}\" doesn't look like a valid e-mail address<br>"  
        else
          @cdata['email'] = email
          @cdata['joinlink'] = "http://#{BASEDOMAIN}/fbjoinlink?comtag=#{@community.tagname}&amp;joincom=1&amp;email=#{email}"

          if @messtext.to_s != ''
            template = Liquid::Template.parse(@messtext)
            html_content = template.render(@cdata)
          else
            html_content = "<p>You have been invited by #{current_participant.email_address_with_name} to join the community: #{@community.fullname}<br/>"
            html_content += "Go <a href=\"#{@cdata['joinlink']}\">here</a> to join.<br>"
            html_content += "</p>"            
          end
        
          subject = "#{current_participant.name} invites you to #{@community.fullname} on InterMix"

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
    @logo = @community.logo.exists? ? "http://#{BASEDOMAIN}#{@community.logo.url}" : "" 
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
    cdata['confirmlink'] = "http://#{@domain}/front/confirm?code=#{@participant.confirmation_token}&group_id=#{@group_id}"
    cdata['logo'] = @logo
    cdata['message'] = '[Custom message]'    
    cdata['subject'] = '[Subject line]'
      
    if @community.send("#{which}_template").to_s != ""
      template_content = render_to_string(:text=>@community.send("#{which}_template"),:layout=>false)
    else
      template_content = render_to_string(:partial=>"#{which}_default",:layout=>false)
    end      
    template = Liquid::Template.parse(template_content)
    render html: template.render(cdata).html_safe, layout: 'front'
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
    @cdata = {}
    @cdata['community'] = @community
    @cdata['community_logo'] = "http://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?
    @cdata['logo'] = "http://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?
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
      redirect_to "/"
      return
    end    
    @community_id = @community.id        
    if participant_signed_in?
      redirect_to "/communities/#{@community_id}"
      return
    end
    @cdata = {}
    @cdata['community'] = @community
    @cdata['community_logo'] = "http://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?
    @cdata['logo'] = "http://#{BASEDOMAIN}#{@community.logo.url}" if @community.logo.exists?
    if @community.front_template.to_s.strip != ''
      desc = Liquid::Template.parse(@community.front_template).render(@cdata)
    else   
      tcontent = render_to_string :partial=>"communities/front_default", :layout=>false
      desc = Liquid::Template.parse(tcontent).render(@cdata)
    end
    @content = "<div>#{desc}</div>"    
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
    params.require(:community).permit(:fullname, :description, :logo, :twitter_post, :twitter_username, :twitter_oauth_token, :twitter_oauth_secret, :twitter_hash_tag, :tweet_approval_min, :tweet_what, :front_template, :member_template, :invite_template, :import_template, :signup_template, :confirm_template, :confirm_email_template, :confirm_welcome_template, :autotags)
  end
  
  def check_is_admin
    @community_id = params[:id].to_i
    @is_admin = false
    if current_participant.sysadmin
      @is_admin = true
    else
      admin = CommunityAdmin.where(["community_id = ? and participant_id = ?", @community_id, current_participant.id]).first
      if admin
        @is_admin = true
      end
    end
  end

end