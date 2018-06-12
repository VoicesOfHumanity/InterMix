# encoding: utf-8

#require 'ostruct'

class FrontController < ApplicationController

	layout "front"
	
	include Magick
	
	before_action :check_status
  
  append_before_action :authenticate_user_from_token!, :only=>[:optout,:optout_confirm]
  append_before_action :authenticate_participant!, :only=>[:optout,:optout_confirm]
  
  def index
    @section = 'home'
    return if redirect_if_not_voh
    session[:sawfront] = 'yes'
    @group_id,@dialog_id = get_group_dialog_from_subdomain
    @content = ""
    cdata = {'cookies'=>cookies}
    if @dialog_id.to_i > 0
      if participant_signed_in?
        redirect_to "#{session[:cur_baseurl]}/dialogs/#{@dialog_id}/slider"
        return
      end
      @dialog = Dialog.find_by_id(@dialog_id)
      @group = Group.find_by_id(@group_id) if @group_id.to_i > 0
      cdata['dialog'] = @dialog if @dialog
      cdata['domain'] = (@dialog and @dialog.shortname.to_s!='') ? "#{@dialog.shortname}.#{ROOTDOMAIN}" : BASEDOMAIN
      cdata['logo'] = "//#{cdata['domain']}#{@dialog.logo.url}" if @dialog and @dialog.logo.exists?
      cdata['dialog_logo'] = "//#{cdata['domain']}#{@dialog.logo.url}" if @dialog and @dialog.logo.exists?
      cdata['group_logo'] = "//#{cdata['domain']}#{@group.logo.url}" if @group and @group.logo.exists?
      cdata['group'] = @group if @group
      if participant_signed_in? and @dialog.member_template.to_s.strip != ''
        desc = Liquid::Template.parse(@dialog.member_template).render(cdata)
      elsif @dialog.front_template.to_s.strip != ''
        desc = Liquid::Template.parse(@dialog.front_template).render(cdata)
      elsif participant_signed_in?
        tcontent = render_to_string :partial=>"dialogs/member_default", :layout=>false
        desc = Liquid::Template.parse(tcontent).render(cdata)        
      else   
        tcontent = render_to_string :partial=>"dialogs/front_default", :layout=>false
        desc = Liquid::Template.parse(tcontent).render(cdata)  
      #else
      #  desc = "<h2>#{@dialog.name}</h2><div>#{@dialog.description}</div>\n"
      end
      @content += "<div>#{desc}</div>"
    elsif @group_id.to_i > 0
      if participant_signed_in?
        redirect_to "/groups/#{@group_id}/forum"
        return
      end
      @group = Group.find_by_id(@group_id)
      cdata['group'] = @group if @group
      cdata['domain'] = (@group and @group.shortname.to_s!='') ? "#{@group.shortname}.#{ROOTDOMAIN}" : BASEDOMAIN
      cdata['logo'] = "//#{cdata['domain']}#{@group.logo.url}" if @group and @group.logo.exists?
      cdata['group_logo'] = "//#{cdata['domain']}#{@group.logo.url}" if @group and @group.logo.exists?
      if participant_signed_in? and @group.member_template.to_s.strip != ''
        desc = Liquid::Template.parse(@group.member_template).render(cdata)
      elsif @group.front_template.to_s.strip != ''
        desc = Liquid::Template.parse(@group.front_template).render(cdata)
      elsif participant_signed_in?
        tcontent = render_to_string :partial=>"groups/member_default", :layout=>false
        desc = Liquid::Template.parse(tcontent).render(cdata)        
      else   
        tcontent = render_to_string :partial=>"groups/front_default", :layout=>false
        desc = Liquid::Template.parse(tcontent).render(cdata)
      #else
      #  desc = "<h2>#{@group.name}</h2><div>#{@group.description}</div>\n"
      end
      @content += "<div>#{desc}</div>"
    else
      @content += "<div style=\"text-align:right;margin:-3px -5px 0 0\"><img src=\"/images/composition.jpg\" width=\"285\" height=\"120\"></div>\n"
    end
    update_last_url
  end  
  
  def photos
    #-- Show everybody's or somebody's pictures
    @participant_id = params[:id].to_i
    @photos = Photo.where(nil)
    @photos = @photos.where(:participant_id=>@participant_id) if @participant_id > 0
    @photos = @photos.where(nil)
    @picdir = "#{DATADIR}/photos"
    @picurl = "/images/data/photos"
    update_last_url
  end  
  
  def photolist
    photos
    render :partial=>'photolist', :layout=>falsed
  end  
  
  def pixel
    #-- Fake pixel, to notice that somebody opened an e-mail (message)
    message_id = params[:id].to_i 
    message = Message.find_by_id(message_id)
    if message
      message.read_email = true
      message.read_at = Time.now
      message.save
    end
    send_file("#{Rails.root}/public/images/pixel.gif", :type => 'image/gif', :filename => "#{message_id}.gif", :disposition => 'inline' )
  end  
  
  def privacy
    #-- Privacy statement
  end  
  
  def optout
    #-- Optout pop-up screen    
    if params[:layout].to_s != ''
      layout = params[:layout].to_s
    else
      layout = 'front'
    end
    render :action=>:optout, :layout=>layout
  end
  
  def optout_confirm
    #-- Opt this person out of e-mailing
    current_participant.no_email = true
    current_participant.save!
  end
  
  def instantjoinform
    #-- For including in another site, e.g. in a sidebar, in an iframe to make it easy to join
    #render :partial=>'instantjoinform', :layout=>false
    @group_id = 8
    @samples = Item.where("items.group_id=#{@group_id} and items.has_picture=1 and items.media_type='picture'").includes(:participant).order("items.id desc").limit(5)
    render :action=>:instantjoinform, :layout=>'blank'
  end  
  
  def instantjointest
    #-- Test page to show how the instant join form might look in a sidebar of another site
    render :action=>:instantjointest, :layout=>'blank'
  end  
  
  def instantjoin
    #-- Process form from an instant form, maybe on another site
    @message = params[:message]
    @name = params[:name]
    @email = params[:email]
    @group_id = params[:group_id].to_i
    tempfilepath = ''
    
    @samples = Item.where("items.group_id=#{@group_id} and items.has_picture=1 and items.media_type='picture'").includes(:participant).order("items.id desc").limit(5)
    
    flash[:alert] = ''
    if @group_id == 0
      flash[:alert] = "Sorry, there's no indication of what group this would be added to<br>"
    elsif @group_id > 0
      @group = Group.find_by_id(@group_id)
      if not @group
        flash[:alert] = "Sorry, this group seems to no longer exist<br>"
      elsif @group.openness != 'open'
        flash[:alert] = "Sorry, this group seems to no longer be open to submissions<br>"
      end    
    end 
    if flash[:alert] != ''
      #redirect_to :action=>:instantjoinform
      render :action=>:instantjoinform, :layout=>'blank'
      return
    end  
    
    if @message == ''
      flash[:alert] = "Please include a short message to show with your picture<br>"
    end  
    if @name == ''
      flash[:alert] = "What's your name?<br>"
    end  
    if @email == ''
      flash[:alert] = "Please type in your e-mail address as well<br>"
    end  
    if not params[:picfile]
      flash[:alert] = "You need to upload a picture<br>"
    end  
    if flash[:alert] != ''
      render :action=>:instantjoinform, :layout=>'blank'
      return
    end  
    
    if params[:picfile] and params[:picfile].original_filename.to_s != ""
      #-- We got an uploaded file
      original_filename = params[:picfile].original_filename.to_s.downcase.gsub(%r{[^a-z0-9_.-]+},'_')
      tempfilepath = "/tmp/#{Time.now.to_i}_#{original_filename}"
      logger.info("front#instantjoin uploaded file:#{original_filename}")      
      f = File.new(tempfilepath, "wb")
      f.write params[:picfile].read
      f.close
    end  

    narr = @name.split(' ')
    last_name = narr[narr.length-1]
    first_name = ''
    first_name = narr[0,narr.length-1].join(' ') if narr.length > 1
    password = 'test'
    
    @participant = Participant.find_by_email(@email) 
    if @participant 
      flash[:notice] = "You seem to already have an account, so we posted it to that<br>"
      redirect_to '/participants/sign_in'
      return
    else
      @participant = Participant.new
      @participant.first_name = first_name
      @participant.last_name = last_name
      @participant.email = @email
      @participant.password = password
      #@participant.country_code = 'US' if state.to_s != ''
      @participant.forum_email = 'daily'
      @participant.group_email = 'daily'
      @participant.subgroup_email = 'daily'
      @participant.private_email = 'instant'  
      @participant.status = 'unconfirmed'
      if not @participant.save!  
        flash[:alert] = "Sorry, there's some kind of database problem<br>"
        render :action=>:instantjoinform, :layout=>'blank'
        return
      end  
    end
    
    @participant.groups << @group
    
    # Also join Global Townhall Square
    group_participant = GroupParticipant.create(group_id: GLOBAL_GROUP_ID, participant_id: @participant.id, active: true, status: 'active')
 
    @item = Item.new
    @item.group_id = @group_id
    @item.item_type = 'message'
    @item.media_type = 'picture'
    @item.posted_by = @participant.id
    @item.is_first_in_thread = true
    @item.posted_to_forum = true
    @item.html_content = @message
    @item.short_content = @message.gsub(/<\/?[^>]*>/, "").strip[0,140]
    @item.posted_via = 'web'    
    @item.save
    @item.create_xml
    @item.first_in_thread = @item.id
 
    @item.add_image(tempfilepath)
    `rm -f #{tempfilepath}`

    @item.save

    @samples = Item.where("items.group_id=#{@group_id} and items.has_picture=1 and items.media_type='picture'").includes(:participant).order("items.id desc").limit(5)

    render :action=>:instantjoinresponse, :layout=>'blank'

  end  
    
  def dialog
    #-- Main screen for a public dialog
    @group_id,@dialog_id = get_group_dialog_from_subdomain    
    @dialog_id = params[:dialog_id].to_i if not @dialog_id
    @group_id = params[:group_id].to_i if not @group_id
    render :action=>:dialog, :layout=>'blank'
  end
  
  def dialogjoinform
    #-- Form for submitting to join a dialog
    @comtag = params[:comtag]
    @group_id,@dialog_id = get_group_dialog_from_subdomain    
    @dialog_id = params[:dialog_id].to_i if not @dialog_id
    @dialog_id = params[:id].to_i if not @dialog_id or @dialog_id == 0
    @group_id = params[:group_id].to_i if not @group_id or @group_id == 0
    @dialog = Dialog.find_by_id(@dialog_id)
    if @dialog and @group_id == 0
      @group_id = @dialog.group_id.to_i
    end 
    @group = Group.find_by_id(@group_id)

    if not @group
      flash[:alert] = "No group was identified"
      redirect_to "//#{BASEDOMAIN}/join" 
      return
    elsif not @dialog
      flash[:alert] = "No discussion was identified"
      redirect_to "//#{BASEDOMAIN}/join" 
      return
    elsif @dialog and current_participant and participant_signed_in?
      flash[:alert] = "You were already logged in. No need to join again."
      redirect_to "//#{@dialog.shortname}.#{ROOTDOMAIN}/"
      return
    elsif @group and current_participant and participant_signed_in?
      flash[:alert] = "You were already logged in. No need to join again."
      redirect_to "//#{@group.shortname}.#{ROOTDOMAIN}/"
      return
    elsif @group and not ( @group.openness == 'open' or @group.openness == 'open_to_apply' )
      flash[:alert] = "Sorry, you can not join that group by yourself"
      redirect_to "//#{BASEDOMAIN}/join" 
      return      
    end
    
    session[:join_group_id] = @group_id
    session[:join_dialog_id] = @dialog_id
    
    prepare_djoin
    
    render :action=>:dialogjoinform
  end
  
  def dialogjoin
    #-- What the discussion join form posts to
    @dialog_id = params[:dialog_id].to_i
    @group_id = params[:group_id].to_i
    logger.info("Front#dialogjoin dialog:#{@dialog_id} group:#{@group_id}")
    
    session[:join_group_id] = nil if session[:join_group_id]
    session[:join_dialog_id] = nil if session[:join_dialog_id]

    if request.get?
      flash[:alert] = "Not allowed"
      redirect_to "//#{BASEDOMAIN}/join" 
      return
    end
    
    @dialog = Dialog.find_by_id(@dialog_id)
    if @dialog and @group_id == 0
      @group_id = @dialog.group_id.to_i
    end 
    @group = Group.find_by_id(@group_id)

    if not @group
      flash[:alert] = "No group was identified"
      redirect_to "//#{BASEDOMAIN}/join" 
      return
    elsif not @dialog
      flash[:alert] = "No discussion was identified"
      redirect_to "//#{BASEDOMAIN}/join" 
      return
    elsif @group and not ( @group.openness == 'open' or @group.openness == 'open_to_apply' )
      flash[:alert] = "Sorry, you can not join that group by yourself"
      redirect_to "//#{BASEDOMAIN}/join" 
      return   
    end     
    
    if @group and @dialog
      #-- Look up the dialog/group setting, which might contain a template
      @dialog_group = DialogGroup.where("group_id=#{@group.id} and dialog_id=#{@dialog.id}").first
    end
    
    @subject = params[:subject].to_s
    @message = params[:message].to_s
    @has_subject = params.has_key?('subject')
    @has_message = params.has_key?('message')
    if params.has_key?(:first_name)
      @first_name = params[:first_name].to_s
      @last_name = params[:last_name].to_s
    else
      @name = params[:name].to_s
    end
    @email = params[:email].to_s
    @country_code = params[:country_code].to_s
    @indigenous = params[:indigenous].to_i
    @other_minority = params[:other_minority].to_i
    @veteran = params[:veteran].to_i
    @interfaith = params[:interfaith].to_i
    @refugee = params[:refugee].to_i
    tempfilepath = ''
    
    flash[:notice] = ''
    flash[:alert] = ''

    if @dialog_id == 0
      flash[:alert] += "Sorry, there's no indication of what discussion this would be added to<br>"
    elsif @dialog_id > 0
      @dialog = Dialog.find_by_id(@dialog_id)
      if not @dialog
        flash[:alert] += "Sorry, this discussion seems to no longer exist<br>"
      elsif @dialog.openness != 'open'
        flash[:alert] += "Sorry, this discussion seems to no longer be open to submissions<br>"
      end    
    end  
    if @group_id == 0
      flash[:alert] += "Sorry, there's no indication of what group this would be added to<br>"
    elsif @group_id > 0
      @group = Group.find_by_id(@group_id)
      if not @group
        flash[:alert] += "Sorry, this group seems to no longer exist<br>"
      elsif @group.openness != 'open'
        flash[:alert] += "Sorry, this group seems to no longer be open to submissions<br>"
      end    
    end 
    if flash[:alert] != ''
      prepare_djoin
      render :action=>:dialogjoinform
      return
    end  

    if not @has_message
    elsif @message.to_s == '' and ((@dialog and @dialog.settings_with_period["required_message"]) or @subject.to_s != '')
      flash[:alert] += "Please include at least a short message<br>"
    elsif @dialog and @dialog.settings_with_period["max_characters"].to_i > 0 and @message.length > @dialog.settings_with_period["max_characters"]  
      flash[:alert] += "The maximum message length is #{@dialog.max_characters} characters<br>"
    elsif @dialog.required_subject and @subject.to_s == '' and @message.gsub(/<\/?[^>]*>/, "").strip != ''
      flash[:alert] += "Please choose a subject line<br>"
    elsif @subject != '' and @subject.length > 48
      flash[:alert] += "Maximum 48 characters for the subject line, please<br>"        
    end
    if params.has_key?(:first_name) and (@first_name == '' and @last_name == '')
      flash[:alert] += "What's your name?<br>"
    elsif @name == ''
      flash[:alert] += "What's your name?<br>"
    end  
    if @email == ''
      flash[:alert] += "Please type in your e-mail address as well<br>"
    elsif not @email =~ /^[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,4}$/
      flash[:alert] += "That doesn't look like a valid e-mail address<br>"
    end  
    flash[:alert] += 'Country is required<br>' if params.has_key?(:country_code) and (params[:country_code].to_s == '' or params[:country_code].to_s == '* choose *')
    @password = '???'    
    if params.include?('password')
      #-- A password has been supplied
      @password = params[:password].to_s
      @password_confirmation = params[:password_confirmation].to_s
      if @password == ''
        flash[:alert] += "Please choose a password<br>"
      elsif @password.length < 4
        flash[:alert] += "Please choose a longer password<br>"
      elsif @password_confirmation == ''
        flash[:alert] += "Please enter your password a second time, to confirm<br>"
      elsif @password_confirmation != @password
        flash[:alert] += "The two passwords don't match<br>"
      end
    else
      #-- Create a password
      @password = ''
      3.times do
        conso = 'bcdfghkmnprstvw'[rand(15)]
        vowel = 'aeiouy'[rand(6)]
        @password += conso +  vowel
        @password += (1+rand(9)).to_s if rand(3) == 2
      end
    end

    @metamap_vals = {}
    if @dialog and @dialog.required_meta
      #-- Check any metamap categories, if they're required
      metamaps = @dialog.metamaps
      for metamap in metamaps
        metamap_id = metamap[0]
        metamap_name = metamap[1]
        val = params["meta_#{metamap_id}"].to_i
        if val == 0
          flash[:alert] += "Please choose your #{metamap_name}<br>"
        end
        @metamap_vals[metamap_id] = val
      end
    end
    if flash[:alert] != ''
      prepare_djoin
      render :action=>:dialogjoinform
      return
    end  

    if params.has_key?(:first_name)
      @last_name = params[:last_name].to_s
      @first_name = params[:first_name].to_s
    else
      narr = @name.split(' ')
      @last_name = narr[narr.length-1]
      @first_name = ''
      @first_name = narr[0,narr.length-1].join(' ') if narr.length > 1
    end
        
    @participant = Participant.find_by_email(@email) 
    previous_messages = 0
    if @participant and @participant.status=='active' and @has_message
      previous_messages = Item.where("posted_by=? and dialog_id=?",@participant.id,@dialog.id).count
      if @dialog.max_messages > 0 and @message.length > 0 and previous_messages >= @dialog.max_messages
        flash[:alert] = "You have already posted a message to this discussion before.<br>You can see the messages when you log in at: //#{@dialog.shortname}.#{ROOTDOMAIN}/<br>"
      elsif @message.length == 0
        flash[:alert] = "You already have an account<br>"
        redirect_to '/participants/sign_in'
        return
      else
        #flash[:notice] = "You seem to already have an account, so we posted it to that<br>"
        flash[:alert] = "You seem to already have an account. Please log into that<br>"
        redirect_to '/participants/sign_in'
        return
      end
    elsif @participant
      # PARTICIPANT_STATUSES = ['unconfirmed','active','inactive','never-contact','disallowed']
      if @participant.status == 'active'
        flash[:alert] = "You already have an active account<br>"
        redirect_to '/participants/sign_in'
        return
      elsif @participant.status == 'inactive'
        flash[:alert] = "Your account is currently not active<br>"
        redirect_to '/participants/sign_in'
        return
      elsif @participant.status == 'never-contact' or @participant.status == 'disallowed'    
        flash[:alert] = "Your account has been closed<br>"
        redirect_to '/participants/sign_in'
        return
      elsif @participant.status == 'unconfirmed'  
        #-- We will update their existing unconfirmed account with what they just entered
        @participant.first_name = @first_name.strip
        @participant.last_name = @last_name.strip
        @participant.password = @password
        @participant.country_code = @country_code
        @participant.forum_email = 'daily'
        @participant.group_email = 'daily'
        @participant.subgroup_email = 'instant'
        @participant.private_email = 'instant'  
        @participant.system_email = 'instant'
        @participant.status = 'unconfirmed'
        @participant.confirmation_token = Digest::MD5.hexdigest(Time.now.to_f.to_s + @email)
      else
        flash[:alert] = "You already have an account<br>"
        redirect_to '/participants/sign_in'
        return
      end    
    else
      @participant = Participant.new
      @participant.first_name = @first_name.strip
      @participant.last_name = @last_name.strip
      @participant.email = @email
      @participant.password = @password
      @participant.country_code = @country_code
      @participant.forum_email = 'daily'
      @participant.group_email = 'instant'
      @participant.subgroup_email = 'instant'
      @participant.private_email = 'instant'  
      @participant.status = 'unconfirmed'
      @participant.confirmation_token = Digest::MD5.hexdigest(Time.now.to_f.to_s + @email)
      @participant.metro_area_id = params[:metro_area_id].to_i
      @participant.city = params[:city].to_s
      @participant.indigenous = (params[:indigenous].to_i == 1)
      @participant.other_minority = (params[:other_minority].to_i == 1)
      @participant.veteran = (params[:veteran].to_i == 1)
      @participant.interfaith = (params[:interfaith].to_i == 1)
      @participant.refugee = (params[:refugee].to_i == 1)
      @participant.tag_list = params[:participant][:tag_list] if params[:participant].has_key?(:tag_list)
    end

    if flash[:alert] != ''
      prepare_djoin
      render :action=>:dialogjoinform
      return
    end  
        
    if not @participant.save!  
      flash[:alert] = "Sorry, there's some kind of database problem<br>"
      render :action=>:dialogjoinform
      return
    end  

    #@participant.groups << @group if not @participant.groups.include?(@group)
    @group_participant = GroupParticipant.new(:group_id=>@group.id,:participant_id=>@participant.id)
    if @group.openness == 'open'
      @group_participant.active = true
      @group_participant.status = 'pending'
    else
      #-- open_to_apply probably
      @group_participant.active = false
      @group_participant.status = 'applied'      
    end
    @group_participant.save
    
    # Also join Global Townhall Square
    group_participant = GroupParticipant.create(group_id: GLOBAL_GROUP_ID, participant_id: @participant.id, active: true, status: 'active')

    @participant.ensure_authentication_token!

    #-- Store their metamap category
    metamaps = @dialog.metamaps
    for metamap in metamaps
      metamap_id = metamap[0]
      val = params["meta_#{metamap_id}"].to_i
      if val > 0
        mnp = MetamapNodeParticipant.where(:metamap_id=>metamap_id,:participant_id=>@participant.id).first
        if mnp
          mnp.metamap_node_id = val
          mnp.save
        else
          MetamapNodeParticipant.create(:metamap_id=>metamap_id,:metamap_node_id=>val,:participant_id=>@participant.id)
        end    
      end
    end

    if flash[:alert] != ''
      render :action=>:dialogjoinform
      return        
    end
    
    if @message.gsub(/<\/?[^>]*>/, "").strip == "Dear Mr. Secretary General,"
      @message = ""
    end
 
    if false and ( @message != '' or @subject != '' )
      #-- For now we're turning off the message posting 
      @item = Item.new
      @item.dialog_id = @dialog_id
      @item.group_id = @group_id
      @item.item_type = 'message'
      @item.media_type = 'text'
      @item.posted_by = @participant.id
      @item.is_first_in_thread = true
      @item.posted_to_forum = true
      @item.subject = @subject
      @item.html_content = @message
      @item.short_content = @message.gsub(/<\/?[^>]*>/, "").strip[0,140]
      @item.posted_via = 'web'    
      @item.save
      @item.create_xml
      @item.first_in_thread = @item.id
      @item.save!
    end
    
    # Pick an appropriate logo
    if @dialog.logo.exists?
      @logo = "//#{BASEDOMAIN}#{@dialog.logo.url}"
    elsif @group.logo.exists?
      @logo = "//#{BASEDOMAIN}#{@group.logo.url}"
    else
      @logo = nil
    end
    logger.info("front#dialogjoin @logo set to #{@logo}")

    if true
      dom = BASEDOMAIN
    elsif @dialog.shortname.to_s != "" and @group.shortname.to_s != ""
      dom = "#{@dialog.shortname}.#{@group.shortname}.#{ROOTDOMAIN}"
    elsif @dialog.shortname.to_s != ""
      dom = "#{@dialog.shortname}.#{ROOTDOMAIN}"
    elsif @group.shortname.to_s != ""
      dom = "#{@group.shortname}.#{ROOTDOMAIN}"
    else
      dom = BASEDOMAIN
    end
    
    #-- Send an e-mail to the member
    recipient = @participant
    cdata = {}
    cdata['item'] = @item
    cdata['recipient'] = @participant     
    cdata['participant'] = @participant 
    cdata['group'] = @group if @group
    cdata['dialog'] = @dialog if @dialog
    cdata['logo'] = @logo if @logo
    cdata['password'] = @password
    cdata['confirmlink'] = "<a href=\"https://#{dom}/front/confirm?code=#{@participant.confirmation_token}&dialog_id=#{@dialog.id}\">https://#{dom}/front/confirm?code=#{@participant.confirmation_token}&dialog_id=#{@dialog.id}</a>"
    cdata['domain'] = dom
    
    if @dialog_group and @dialog_group.confirm_email_template.to_s.strip != ''
      template = Liquid::Template.parse(@dialog_group.confirm_email_template)
      html_content = template.render(cdata)
    elsif @dialog.confirm_email_template.to_s.strip != ''
      template = Liquid::Template.parse(@dialog.confirm_email_template)
      html_content = template.render(cdata)
    else    
      html_content = "<p>Welcome!</p><p>username: #{@participant.email}<br/>"
      html_content += "password: #{@password}<br/>" if @password != '???'
      
      html_content += "<br/>As the first step, please click this link, to confirm that it really was you who signed up, and to log in the first time:<br/><br/>"
      html_content += "https://#{dom}/front/confirm?code=#{@participant.confirmation_token}&dialog_id=#{@dialog.id}<br/><br/>"
      
      #html_content += "<br/>Click <a href=\"http://#{dom}/?auth_token=#{@participant.authentication_token}\">here</a> to log in the first time, or enter your username/password at http://#{dom}/<br/><br/>"
      
      html_content += "(If it wasn't you, just do nothing, and nothing further happens)<br/>"
      
      #html_content += "If you have lost your password: http://#{dom}/participants/password/new<br/>"   
      html_content += "</p>"
    end
  
    email = @participant.email
    msubject = "[#{@dialog.shortname}] Signup"
    email = SystemMailer.generic(SYSTEM_SENDER, @participant.email_address_with_name, msubject, html_content, cdata)

    begin
      logger.info("Item#emailit delivering email to #{recipient.id}:#{recipient.name}")
      email.deliver
      message_id = email.message_id
    rescue Exception => e
      logger.info("Item#emailit problem delivering email to #{recipient.id}:#{recipient.name}: #{e}")
    end

    if @dialog_group and @dialog_group.confirm_template.to_s != ''
      template = Liquid::Template.parse(@dialog_group.confirm_template)
      @content = template.render(cdata)
    elsif @dialog.confirm_template.to_s != ''
      template = Liquid::Template.parse(@dialog.confirm_template)
      @content = template.render(cdata)
    elsif true
      confirm_template = render_to_string :partial=>"dialogs/confirm_default", :layout=>false
      template = Liquid::Template.parse(confirm_template)
      @content = template.render(cdata)
    else
      @content = ""
      @content += "<p><img src=\"#{@logo}\"/></p>" if @logo
      #@content += "<p>Thank you! We've sent you an e-mail with your username and password. This e-mail also contains a confirmation link. Please click on that link to continue. This is simply to confirm that you really are you.</p>"
      @content += "<p align=\"center\"><big><b>#{@group.name}</b> Signup Success!</big></p>"
      @content += "<p>A confirmation email has been sent to the email address you provided. Please check your inbox. If you have not received the email within a few minutes, be sure to check your spam folder. You must click the link in that email to confirm it really was you who signed up.</p>"
    end
    
    cookies["d_#{@dialog.shortname}"] = { :value => "joined", :expires => Time.now + 30*3600}
    
    render :action=>:confirm, :layout=>'front'
  end  
        
  def groupjoinform
    #-- Form for submitting to join a group
    @group_id,@dialog_id = get_group_dialog_from_subdomain    
    @dialog_id = params[:dialog_id].to_i if not @dialog_id
    @dialog_id = params[:id].to_i if not @dialog_id or @dialog_id == 0
    @group_id = params[:group_id].to_i if not @group_id or @group_id == 0
    @dialog = Dialog.find_by_id(@dialog_id)
    if @dialog and @group_id == 0
      @group_id = @dialog.group_id.to_i
    end 
    @group = Group.find_by_id(@group_id)
    @email = params[:email].to_s
    
    if not @group
      flash[:alert] = "Group not found"
      redirect_to "//#{BASEDOMAIN}/join"
      return  
    elsif @dialog and current_participant and participant_signed_in?
      flash[:alert] = "You were already logged in. No need to join again."
      redirect_to "//#{@dialog.shortname}.#{ROOTDOMAIN}/"
      return
    elsif @group.shortname.to_s != '' and current_participant and participant_signed_in?
      flash[:alert] = "You were already logged in. No need to join again."
      redirect_to "//#{@group.shortname}.#{ROOTDOMAIN}/"
      return
    elsif @group.openness == 'private'
      render inline: "This is a private group", :layout => 'front'
      return
    elsif @group.openness == 'by_invitation_only'
      render inline: "You have to be invited to join this group", :layout => 'front'
      return
    elsif @group.openness == 'open_to_apply'
      #render :text=>"You can apply to join this group", :layout => 'front'
      #return
    elsif @group.openness != 'open'
      render inline: "This group is not open to join directly", :layout => 'front'
      return
    end
    
    session[:join_group_id] = @group_id
    session[:join_dialog_id] = @dialog_id
    
    prepare_gjoin
    
    render :action=>:groupjoinform, :layout => 'front'
  end  
    
  def groupjoin
    #-- What the group join form posts to
    @group_id = params[:group_id].to_i
    logger.info("Front#groupjoin group:#{@group_id}")

    session[:join_group_id] = nil if session[:join_group_id]
    session[:join_dialog_id] = nil if session[:join_dialog_id]

    if request.get?
      flash[:alert] = "Not allowed"
      redirect_to "//#{BASEDOMAIN}/join" 
      return
    end
    
    @group = Group.find_by_id(@group_id)

    if params.has_key?(:first_name)
      @first_name = params[:first_name].to_s
      @last_name = params[:last_name].to_s
    else
      @name = params[:name].to_s
    end
    @email = params[:email].to_s
    @country_code = params[:country_code].to_s
    @indigenous = params[:indigenous].to_i
    @other_minority = params[:other_minority].to_i
    @veteran = params[:veteran].to_i
    @interfaith = params[:interfaith].to_i
    @refugee = params[:refugee].to_i
    tempfilepath = ''
    
    flash[:notice] = ''
    flash[:alert] = '' 
    if @group_id == 0
      flash[:alert] += "Sorry, there's no indication of what group this would be added to<br>"
    elsif @group_id > 0
      @group = Group.find_by_id(@group_id)
      if not @group
        flash[:alert] += "Sorry, this group seems to no longer exist<br>"
      elsif @group.openness == 'private'
        flash[:alert] += "Sorry, this is a private group, which you can't join this way.<br>"
      elsif @group.openness == 'by_invitation_only'
        flash[:alert] += "Sorry, you have to be invited to join this group<br>"
      elsif @group.openness != 'open' and @group.openness != 'open_to_apply'
        flash[:alert] += "Sorry, this group seems to no longer be open to submissions<br>"
      end    
    end 
    if flash[:alert] != ''
      prepare_gjoin
      render :action=>:groupjoinform
      return
    end  

    if params.has_key?(:first_name) and (@first_name == '' and @last_name == '')
      flash[:alert] += "What's your name?<br>"
    elsif @name == ''
      flash[:alert] += "What's your name?<br>"
    end  
    if @email == ''
      flash[:alert] += "Please type in your e-mail address as well<br>"
    elsif not @email =~ /^[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,4}$/
      flash[:alert] += "That doesn't look like a valid e-mail address<br>"
    end  
    flash[:alert] += 'Country is required<br>' if params.has_key?(:country_code) and (params[:country_code].to_s == '' or params[:country_code].to_s == '* choose *')
    @password = '???'    
    if params.include?('password')
      #-- A password has been supplied
      @password = params[:password].to_s
      @password_confirmation = params[:password_confirmation].to_s
      if @password == ''
        flash[:alert] += "Please choose a password<br>"
      elsif @password_confirmation == ''
        flash[:alert] += "Please enter your password a second time, to confirm<br>"
      elsif @password_confirmation != @password
        flash[:alert] += "The two passwords don't match<br>"
      end
    else
      #-- Create a password
      @password = ''
      3.times do
        conso = 'bcdfghkmnprstvw'[rand(15)]
        vowel = 'aeiouy'[rand(6)]
        @password += conso +  vowel
        @password += (1+rand(9)).to_s if rand(3) == 2
      end
    end

    @metamap_vals = {}
    if @group.required_meta
      #-- Check any metamap categories, if they're required
      metamaps = @group.metamaps_own
      for metamap in metamaps
        val = params["meta_#{metamap.id}"].to_i
        if val == 0
          flash[:alert] += "Please choose your #{metamap.name}<br>"
        end
        @metamap_vals[metamap.id] = val
      end
    end
    if flash[:alert] != ''
      prepare_gjoin
      render :action=>:groupjoinform
      return
    end  

    if params.has_key?(:first_name)
      @last_name = params[:last_name].to_s
      @first_name = params[:first_name].to_s
    else
      narr = @name.split(' ')
      @last_name = narr[narr.length-1]
      @first_name = ''
      @first_name = narr[0,narr.length-1].join(' ') if narr.length > 1
    end
        
    @participant = Participant.find_by_email(@email) 
    previous_messages = 0
    if @participant
      # PARTICIPANT_STATUSES = ['unconfirmed','active','inactive','never-contact','disallowed']
      if @participant.status == 'active'
        flash[:alert] = "You already have an active account. Please log into that<br>"
        redirect_to '/participants/sign_in'
        return
      elsif @participant.status == 'inactive'
        flash[:alert] = "Your account is currently not active<br>"
        redirect_to '/participants/sign_in'
        return
      elsif @participant.status == 'never-contact' or @participant.status == 'disallowed'    
        flash[:alert] = "Your account has been closed<br>"
        redirect_to '/participants/sign_in'
        return
      elsif @participant.status == 'unconfirmed'  
        #-- We will update their existing unconfirmed account with what they just entered
        @participant.first_name = @first_name.strip
        @participant.last_name = @last_name.strip
        @participant.password = @password
        @participant.country_code = @country_code
        @participant.forum_email = 'daily'
        @participant.group_email = 'instant'
        @participant.subgroup_email = 'instant'
        @participant.private_email = 'instant'  
        @participant.status = 'unconfirmed'
        @participant.confirmation_token = Digest::MD5.hexdigest(Time.now.to_f.to_s + @email)
      else
        flash[:alert] = "You already have an account<br>"
        redirect_to '/participants/sign_in'
        return
      end    
    else
      @participant = Participant.new
      @participant.first_name = @first_name.strip
      @participant.last_name = @last_name.strip
      @participant.email = @email
      @participant.password = @password
      @participant.country_code = @country_code
      @participant.forum_email = 'daily'
      @participant.group_email = 'daily'
      @participant.subgroup_email = 'instant'
      @participant.private_email = 'instant'  
      @participant.status = 'unconfirmed'
      @participant.confirmation_token = Digest::MD5.hexdigest(Time.now.to_f.to_s + @email)
      @participant.metro_area_id = params[:metro_area_id].to_i
      @participant.city = params[:city].to_s
      @participant.indigenous = (params[:indigenous].to_i == 1)
      @participant.other_minority = (params[:other_minority].to_i == 1)
      @participant.veteran = (params[:veteran].to_i == 1)
      @participant.interfaith = (params[:interfaith].to_i == 1)
      @participant.refugee = (params[:refugee].to_i == 1)
    end

    if not @participant.save!  
      flash[:alert] = "Sorry, there's some kind of database problem<br>"
      render :action=>:groupjoinform
      return
    end  
    
    #@participant.groups << @group if not @participant.groups.include?(@group)
    @group_participant = GroupParticipant.new(:group_id=>@group.id,:participant_id=>@participant.id)
    if @group.openness == 'open'
      @group_participant.active = true
      @group_participant.status = 'pending'
    else
      #-- open_to_apply probably
      @group_participant.active = false
      @group_participant.status = 'applied'      
    end
    @group_participant.save

    # Also join Global Townhall Square
    group_participant = GroupParticipant.create(group_id: GLOBAL_GROUP_ID, participant_id: @participant.id, active: true, status: 'active')
        
    @participant.ensure_authentication_token!

    #-- Store their metamap category
    metamaps = @group.metamaps_own
    for metamap in metamaps
      val = params["meta_#{metamap.id}"].to_i
      if val > 0
        mnp = MetamapNodeParticipant.where(:metamap_id=>metamap.id,:participant_id=>@participant.id).first
        if mnp
          mnp.metamap_node_id = val
          mnp.save
        else
          MetamapNodeParticipant.create(:metamap_id=>metamap.id,:metamap_node_id=>val,:participant_id=>@participant.id)
        end    
      end
    end

    if flash[:alert] != ''
      render :action=>:groupjoinform
      return        
    end
    
    # Pick an appropriate logo
    if @group.logo.exists?
      @logo = "//#{BASEDOMAIN}#{@group.logo.url}"
    else
      @logo = nil
    end
    logger.info("front#groupjoin @logo set to #{@logo}")

    if true
      dom = BASEDOMAIN
    elsif @group.shortname.to_s != ""
      dom = "#{@group.shortname}.#{ROOTDOMAIN}"
    else
      dom = BASEDOMAIN
    end
    
    #-- Send an e-mail to the member
    recipient = @participant
    cdata = {}
    cdata['item'] = @item
    cdata['recipient'] = @participant     
    cdata['participant'] = @participant 
    cdata['group'] = @group if @group
    cdata['group_logo'] = "//#{BASEDOMAIN}#{@group.logo.url}" if @group.logo.exists?
    cdata['logo'] = @logo if @logo
    cdata['password'] = @password
    cdata['confirmlink'] = "<a href=\"https://#{dom}/front/confirm?code=#{@participant.confirmation_token}&group_id=#{@group.id}\">https://#{dom}/front/confirm?code=#{@participant.confirmation_token}&group_id=#{@group.id}</a>"
    cdata['domain'] = dom
    
    if @group.confirm_email_template.to_s.strip != ''
      template = Liquid::Template.parse(@group.confirm_email_template)
      html_content = template.render(cdata)
    elsif true
      confirm_email_template = render_to_string :partial=>"groups/confirm_email_default", :layout=>false
      template = Liquid::Template.parse(confirm_email_template)
      html_content = template.render(cdata)
    else    
      html_content = "<p>Welcome!</p><p>username: #{@participant.email}<br/>"
      html_content += "password: #{@password}<br/>" if @password != '???'
      
      html_content += "<br/>As the first step, please click this link, to confirm that it really was you who signed up, and to log in the first time:<br/><br/>"
      html_content += "https://#{dom}/front/confirm?code=#{@participant.confirmation_token}&group_id=#{@group.id}<br/><br/>"
      
      #html_content += "<br/>Click <a href=\"http://#{dom}/front/confirm?code=#{@participant.confirmation_token}&group_id=#{@group.id}\">here</a> to log in the first time, or enter your username/password at http://#{dom}/<br/><br/>"
      
      html_content += "(If it wasn't you, just do nothing, and nothing further happens)<br/>"
      
      #html_content += "<br/>Then you'll be able to log in at any time at http://#{dom}/<br/>"
      #html_content += "If you have lost your password: http://#{dom}/participants/password/new<br/>"   
      html_content += "</p>"
    end
  
    email = @participant.email
    msubject = "[#{@group.shortname}] Signup"
    email = SystemMailer.generic(SYSTEM_SENDER, @participant.email_address_with_name, msubject, html_content, cdata)

    begin
      logger.info("front#groupjoin delivering email to #{recipient.id}:#{recipient.name}")
      email.deliver
      message_id = email.message_id
    rescue Exception => e
      logger.info("front#groupjoin problem delivering email to #{recipient.id}:#{recipient.name}: #{e}")
    end
    
    if @group.confirm_template.to_s != ''
      template = Liquid::Template.parse(@group.confirm_template)
      @content = template.render(cdata)
    elsif true
      confirm_template = render_to_string :partial=>"groups/confirm_default", :layout=>false
      template = Liquid::Template.parse(confirm_template)
      @content = template.render(cdata)
    else
      @content = ""
      @content += "<p><img src=\"#{@logo}\"/></p>" if @logo
      #@content += "<p>Thank you! We've sent you an e-mail with your username and password. This e-mail also contains a confirmation link. Please click on that link to continue. This is simply to confirm that you really are you.</p>"
      @content += "<p align=\"center\"><big><b>#{@group.name}</b> Signup Success!</big></p>"
      @content += "<p>A confirmation email has been sent to the email address you provided. Please check your inbox. If you have not received the email within a few minutes, be sure to check your spam folder. You must click the link in that email to confirm it really was you who signed up.</p>"
    end
    
    cookies["g_#{@group.shortname}"] = { :value => "joined", :expires => Time.now + 30*3600}
    
    render :action=>:confirm, :layout=>'front'
  end  
    
  def confirm
    #-- End point of the confirmation link in e-mail, when signing up
    @participant = Participant.find_by_confirmation_token(params[:code])
    @content = ""
    @content += "<p><img src=\"#{@logo}\"/></p>" if @logo
    if @participant
      @participant.status = 'active'
      @participant.new_signup = true
      @participant.save
      group_participants = GroupParticipant.where(:participant_id=>@participant.id).includes(:group=>:moderators)
      for group_participant in group_participants
        #-- Activate any group memberships that were waiting for the person to confirm
        if group_participant.status == 'pending'
          group_participant.status = 'active'
          group_participant.active = true
          group_participant.save
        elsif group_participant.status == 'applied' and group_participant.group.openness == 'open_to_apply'
          #-- Send a message to the group administrator, if it is an application to approve
          subject = "Application to join #{group_participant.group.name}"
          content = "<p>#{@participant.name} would like to join #{group_participant.group.name}. A group moderator needs to approve or disapprove.</p>"
          for mod in group_participant.group.moderators
            email = SystemMailer.generic(SYSTEM_SENDER, mod.email_address_with_name, subject, content, {})    
          end          
        end
      end
      sign_in(:participant, @participant)
      session[:has_required] = @participant.has_required
      group_id,dialog_id = check_group_and_dialog
      dialog_id = params[:dialog_id].to_i if dialog_id.to_i == 0
      group_id = params[:group_id].to_i if group_id.to_i == 0
      logger.info("front#confirm group:#{group_id} dialog:#{dialog_id}")
      @dialog = Dialog.find_by_id(dialog_id) if dialog_id > 0
      @group = Group.find_by_id(group_id) if group_id > 0
      if @group and @dialog
        #-- Look up the dialog/group setting, which might contain a template
        @dialog_group = DialogGroup.where("group_id=#{@group.id} and dialog_id=#{@dialog.id}").first
      end
      cdata = {}
      cdata['recipient'] = @participant     
      cdata['participant'] = @participant 
      cdata['group'] = @group if @group
      cdata['dialog'] = @dialog if @dialog
      cdata['group_logo'] = "//#{BASEDOMAIN}#{@group.logo.url}" if @group and @group.logo.exists?
      cdata['dialog_logo'] = "//#{BASEDOMAIN}#{@dialog.logo.url}" if @dialog and @dialog.logo.exists?
      cdata['domain'] = BASEDOMAIN
      #if @dialog
      #  @content += "<p>Thank you for confirming!<br><br>You are already logged in.<br><br>Click on <a href=\"http://#{@dialog.shortname}.#{ROOTDOMAIN}/dialogs/#{@dialog.id}/forum\">Discussion</a> on the left to see the messages.<br><br>Bookmark this link so you can come back later:<br><br><a href=\"http://#{@dialog.shortname}.#{ROOTDOMAIN}/\">http://#{@dialog.shortname}.#{ROOTDOMAIN}/</a>.</p>"
      #  session[:new_signup] = 1
      #  redirect_to "/dialogs/#{@dialog.id}/forum"
      #  return
      if @dialog and @group
        cdata['domain'] = "#{@dialog.shortname}.#{@group.shortname}.#{ROOTDOMAIN}" if @dialog.shortname.to_s != "" and @group.shortname.to_s != ""
        cdata['logo'] = "//#{BASEDOMAIN}#{@group.logo.url}" if @group.logo.exists?
        if @dialog_group and @dialog_group.confirm_welcome_template.to_s != ''
          template = Liquid::Template.parse(@dialog_group.confirm_welcome_template)
          @content = template.render(cdata)
        elsif @dialog.confirm_welcome_template.to_s != ''
          template = Liquid::Template.parse(@dialog.confirm_welcome_template)
          @content += template.render(cdata)
        elsif true
          confirm_welcome_template = render_to_string :partial=>"dialogs/confirm_welcome_default", :layout=>false
          template = Liquid::Template.parse(confirm_welcome_template)
          @content += template.render(cdata)
        else    
          @content += "<p>Thank you for confirming! You can now go to: <a href=\"//#{BASEDOMAIN}/dialogs/#{@dialog.id}/slider\">https://#{BASEDOMAIN}/dialogs/#{@dialog.id}/slider</a> to see the messages. You are already logged in.</p>"
        end
      elsif @group  
        cdata['domain'] = "#{@group.shortname}.#{ROOTDOMAIN}" if @group.shortname.to_s != ""
        cdata['logo'] = "//#{BASEDOMAIN}#{@group.logo.url}" if @group.logo.exists?
        if @group.confirm_welcome_template.to_s != ''
          template = Liquid::Template.parse(@group.confirm_welcome_template)
          @content += template.render(cdata)
        elsif true
          confirm_welcome_template = render_to_string :partial=>"groups/confirm_welcome_default", :layout=>false
          template = Liquid::Template.parse(confirm_welcome_template)
          @content += template.render(cdata)
        else    
          #@content += "<p>Thank you for confirming! You can now go to: <a href=\"http://#{BASEDOMAIN}/groups/#{@group.id}/forum\">http://#{BASEDOMAIN}/groups/#{@group.id}/forum</a> to see the messages. You are already logged in.</p>"
          @content += "<p>Thank you for confirming! You can now go to: <a href=\"//#{BASEDOMAIN}/groups/#{@group.id}/forum\">https://#{BASEDOMAIN}/groups/#{@group.id}/forum</a> to see the messages. You are already logged in.</p>"
        end
      else
        @content += "<p>Thank you for confirming! You can now go to: <a href=\"//#{BASEDOMAIN}/\">https://#{BASEDOMAIN}/</a>. You are already logged in.</p>"
      end
    else
      @content += "not recognized"
    end
    
    render :action=>:confirm, :layout=>'front'
  end  
  
  def fbjoinlink
    #-- Meant as a direct link to join with FB, keeping the comtag settings
    if params[:comtag].to_s != ''
      session[:comtag] = params[:comtag]
      if params.has_key?(:joincom)
        if participant_signed_in?
          #-- Join them right away if logged in
          comtag = session[:comtag]
          comtag.gsub!(/[^0-9A-za-z_]/,'')
          comtag.downcase!
          if ['VoiceOfMen','VoiceOfWomen','VoiceOfYouth','VoiceOfExperience','VoiceOfExperie','VoiceOfWisdom'].include? comtag
          elsif comtag != ''
            current_participant.tag_list.add(comtag)
          end
          current_participant.save
          #-- Send them there
          redirect_to "/dialogs/#{VOH_DISCUSSION_ID}/slider?comtag=#{comtag}"
          return
        else
          session[:joincom] = 1
        end
      end
    end
    redirect_to "/participants/auth/facebook"
  end
  
  def fbjoinform
    #-- Show a signup form allowing people to join with facebook, not asking them anything other than the group they want
    #-- We'll assume they already have been authenticated by facebook
    
  end 
  
  def fbjoin
    #-- The user has selected a group. We'll remember that, and move on to facebook authentication
    #-- If a group hasn't been selected, show the screen to do so
    #-- We'll assume they already have been authenticated by facebook
    
    @group_id = params[:group_id].to_i
    @group_id,@dialog_id = get_group_dialog_from_subdomain if @group_id == 0
    @group_id = session[:join_group_id].to_i if @group_id == 0
    
    flash[:alert] = ''
    
    #if @group_id == 0
    #  #flash[:alert] += "You'll need to choose what group to join<br>"
    #  redirect_to '/fbjoin'     # fbjoinform
    #  return   
    if @group_id > 0
      @group = Group.find_by_id(@group_id)
      if not @group
        flash[:alert] += "Sorry, that group seems to no longer exist<br>"
      elsif @group.openness == 'private'
        flash[:alert] += "Sorry, that is a private group, which you can't join this way.<br>"
      elsif @group.openness == 'by_invitation_only'
        flash[:alert] += "Sorry, you have to be invited to join that group<br>"
      elsif @group.openness != 'open' and @group.openness != 'open_to_apply'
        flash[:alert] += "Sorry, that group seems to no longer be open to submissions<br>"
      end    
      if flash[:alert] != ''
        redirect_to '/fbjoin'    # fbjoinform
        return   
      end
    else
      @group = GLOBAL_GROUP_ID  
    end 
    
    session[:join_group_id] = @group_id
    #redirect_to '/participants/auth/facebook'
    redirect_to '/front/fbjoinfinal'
  end  
  
  def fbjoinfinal
    #-- Joining after authenticating with facebook.
    #-- That happens in the authentications controller, which already should have checked that they don't already have an account
    #-- The Facebook information is found in session[:omniauth]
    #-- The selected group and maybe discussion should be in session[:join_group_id] and session[:join_dialog_id]
    #-- No user account has been created yet, and the signup might still fail, if something is wrong.
    
    if not session[:omniauth]
      #-- If somehow they aren't authorized, do that first
      redirect_to '/participants/auth/facebook'
      return
    end  
    
    flash[:notice] = ''
    flash[:alert] = '' 
    
    flash[:notice] += "You have successfully authenticated with Facebook"
    logger.info("front#fbjoinfinal authenticated with Facebook")
    
    @group_id = session[:join_group_id].to_i
    @dialog_id = session[:join_dialog_id].to_i
    
    session[:join_group_id] = nil if session[:join_group_id]
    session[:join_dialog_id] = nil if session[:join_dialog_id]
    
    #if @group_id == 0
    #  flash[:alert] += "But, sorry, there's no indication of what group this would be added to<br>"
    if @group_id > 0
      @group = Group.find_by_id(@group_id)
      if not @group
        flash[:alert] += "But, sorry, this group seems to no longer exist<br>"
      elsif @group.openness == 'private'
        flash[:alert] += "But, sorry, this is a private group, which you can't join this way.<br>"
      elsif @group.openness == 'by_invitation_only'
        flash[:alert] += "But, sorry, you have to be invited to join this group<br>"
      elsif @group.openness != 'open' and @group.openness != 'open_to_apply'
        flash[:alert] += "But, sorry, this group seems to no longer be open to submissions<br>"
      end    
    end 
    if flash[:alert] != ''
      redirect_to '/fbjoin' 
      return   
    end
    
    omniauth = session[:omniauth]
    
    @participant = Participant.new
    #-- This should set email, first/last name, fb uid/link
    @participant.apply_omniauth(omniauth)

    #-- See if we have a city and country
    if omniauth['info']['location'].to_s != ''
      loc = omniauth['info']['location']
      xarr = loc.split(/, /)
      xcountry = ''
      if xarr.length > 1
        @participant.city = xarr[0]
        xcountry = xarr[1]
      elsif xarr.length == 1
        xcountry = xarr[0]
      end    
      if xcountry != ''
        country = Geocountry.find_by_name(xcountry)
        if country
          @participant.country_code = country.iso
          @participant.country_name = country.name
        else
          #-- Isn't a country. Probably a US state
          @participant.country_code = 'US'
          @participant.country_name = 'United States'
        end
      end
    else
      @participant.country_code = 'US'
      @participant.country_name = 'United States'  
    end  

    #-- Create a password automatically
    @password = ''
    3.times do
      conso = 'bcdfghkmnprstvw'[rand(15)]
      vowel = 'aeiouy'[rand(6)]
      @password += conso +  vowel
      @password += (1+rand(9)).to_s if rand(3) == 2
    end

    @participant.password = @password
    @participant.forum_email = 'daily'
    @participant.group_email = 'instant'
    @participant.subgroup_email = 'instant'
    @participant.private_email = 'instant'  
    @participant.status = 'unconfirmed'   # we will change that a little later
    @participant.confirmation_token = Digest::MD5.hexdigest(Time.now.to_f.to_s + @participant.email)

    if not @participant.save!  
      flash[:alert] = "Sorry, there's some kind of database problem<br>"
      redirect_to '/fbjoin' 
      return   
    end  
    
    if @group
      @group_participant = GroupParticipant.new(:group_id=>@group.id,:participant_id=>@participant.id)
      if @group.openness == 'open'
        @group_participant.active = true
        @group_participant.status = 'active'
      else
        #-- open_to_apply probably
        @group_participant.active = false
        @group_participant.status = 'applied'      
      end
      @group_participant.save
    else
      @group = Group.find_by_id(GLOBAL_GROUP_ID)  
    end

    if @group.id != GLOBAL_GROUP_ID
      # Also join Global Townhall Square, if not already done
      @group_participant = GroupParticipant.create(group_id: GLOBAL_GROUP_ID, participant_id: @participant.id, active: true, status: 'active')
    end

    if session.has_key?(:comtag) and session.has_key?(:joincom)
      # They should be joined to a community, if they aren't already a member ?comtag=love&joincom=1
      logger.info("front#fbjoinfinal joining to community #{session[:comtag]}")
      comtag = session[:comtag]
      comtag.gsub!(/[^0-9A-za-z_]/,'')
      comtag.downcase!
      if ['VoiceOfMen','VoiceOfWomen','VoiceOfYouth','VoiceOfExperience','VoiceOfExperie','VoiceOfWisdom'].include? comtag
      elsif comtag != ''
        @participant.tag_list.add(comtag)
      end
      @participant.save
      session.delete(:joincom)
    end
        
    if @participant.fb_uid.to_i >0 and not @participant.picture.exists?
      #-- Use their facebook photo, if they don't already have one.
      url = "https://graph.facebook.com/#{@participant.fb_uid}/picture?type=large"
      @participant.picture = URI.parse(url).open
      @participant.save!
    end
        
    @participant.ensure_authentication_token!
    
    # Pick an appropriate logo
    if @group and @group.logo.exists?
      @logo = "//#{BASEDOMAIN}#{@group.logo.url}"
    else
      @logo = nil
    end

    if true
      dom = BASEDOMAIN
    elsif @group and @group.shortname.to_s != ""
      dom = "#{@group.shortname}.#{ROOTDOMAIN}"
    else
      dom = BASEDOMAIN
    end
    
    #-- Send an e-mail to the member
    recipient = @participant
    cdata = {}
    cdata['item'] = @item
    cdata['recipient'] = @participant     
    cdata['participant'] = @participant 
    cdata['group'] = @group if @group
    cdata['group_logo'] = "//#{BASEDOMAIN}#{@group.logo.url}" if @group.logo.exists?
    cdata['logo'] = @logo if @logo
    cdata['password'] = @password
    cdata['domain'] = dom
    cdata['forumurl'] = "//#{dom}/groups/#{@group.id}/forum"
    
    #if @group.confirm_email_template.to_s.strip != ''
    #  template = Liquid::Template.parse(@group.confirm_email_template)
    #  html_content = template.render(cdata)
    if true
      confirm_email_template = render_to_string :partial=>"groups/confirm_email_default", :layout=>false
      template = Liquid::Template.parse(confirm_email_template)
      html_content = template.render(cdata)
    else    
      html_content = "<p>Welcome! You have signed up through Facebook. In case you should need it, you can also use this login info:</p>"
      
      html_content = "<p>username: #{@participant.email}<br/>"
      html_content += "password: #{@password}<br/>" if @password != '???'
      
      html_content += "<br/>Click here to log in the first time:<br/><br/>"
      html_content += "https://#{dom}/front/confirm?code=#{@participant.confirmation_token}&group_id=#{@group.id}<br/><br/>"
      
      html_content += "(If it wasn't you, just do nothing, and nothing further happens)<br/>"
      html_content += "</p>"
    end
  
    email = @participant.email
    msubject = "[#{@group.shortname}] Signup"
    email = SystemMailer.generic(SYSTEM_SENDER, @participant.email_address_with_name, msubject, html_content, cdata)

    begin
      logger.info("front#fbjoinfinal delivering email to #{recipient.id}:#{recipient.name}")
      email.deliver
      message_id = email.message_id
    rescue Exception => e
      logger.info("front#fbjoinfinal problem delivering email to #{recipient.id}:#{recipient.name}: #{e}")
    end
    
    #if @group.confirm_template.to_s != ''
    #  template = Liquid::Template.parse(@group.confirm_template)
    #  @content = template.render(cdata)
    #elsif true
#      confirm_template = render_to_string :partial=>"groups/confirm_default", :layout=>false
#      template = Liquid::Template.parse(confirm_template)
#      @content = template.render(cdata)
    #else
    #  @content = ""
    #  @content += "<p><img src=\"#{@logo}\"/></p>" if @logo
    #  #@content += "<p>Thank you! We've sent you an e-mail with your username and password. This e-mail also contains a confirmation link. Please click on that link to continue. This is simply to confirm that you really are you.</p>"
    #  @content += "<p align=\"center\"><big><b>#{@group.name}</b> Signup Success!</big></p>"
    #  @content += "<p>A confirmation email has been sent to the email address you provided. Please check your inbox. If you have not received the email within a few minutes, be sure to check your spam folder. You must click the link in that email to confirm it really was you who signed up.</p>"
    #end
    
    cookies["g_#{@group.shortname}"] = { :value => "joined", :expires => Time.now + 30*3600}
    
    flash[:notice] = "Your account has been created and you're now signed in."
    @participant.status = 'active'
    @participant.new_signup = true
    @participant.save
    
    #sign_in_and_redirect(:participant, @participant)
    sign_in(:participant, @participant)
    
    #redirect_to '/me/profile/edit'
    redirect_to "/dialogs/#{VOH_DISCUSSION_ID}/slider"
    
    #render :action=>:confirm, :layout=>'front'
    
  end   

  
  def notconfirmed
  end
  
  def joinform
    #-- General join form where one can shoose a group
    prepare_join
    
    render :action=>:joinform
    
  end  
  
  def join
    #-- General join
    
    logger.info("Front#join")

    session[:join_group_id] = nil if session[:join_group_id]
    session[:join_dialog_id] = nil if session[:join_dialog_id]

    if request.get?
      flash[:alert] = "Not allowed"
      redirect_to "//#{BASEDOMAIN}/join" 
      return
    end

    @email = params[:email].to_s
    @first_name = params[:first_name].to_s
    @last_name = params[:last_name].to_s
    @group_id = params[:group_id].to_i
    @country_code = params[:country_code].to_s
    
    #-- Do a bit of validation
    flash[:alert] = ''
    if @first_name == '' and @last_name == ''
      flash[:alert] += "Please enter your name<br>"
    end
    if @email == ''
      flash[:alert] += "Please type in your e-mail address as well<br>"
    elsif not @email =~ /^[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,4}$/
      flash[:alert] += "That doesn't look like a valid e-mail address<br>"
    end  
    flash[:alert] += 'Country is required<br>' if params.has_key?(:country_code) and (params[:country_code].to_s == '' or params[:country_code].to_s == '* choose *')
    @participant = Participant.find_by_email(@email) 
    if @group_id == 0
      flash[:alert] += "Please choose a group to join<br>"
    elsif @group_id > 0
      @group = Group.find_by_id(@group_id)
      if not @group
        flash[:alert] += "Sorry, this group seems to no longer exist<br>"
      elsif @group.openness != 'open'
        flash[:alert] += "Sorry, this group seems to no longer be open to submissions<br>"
      end    
    end 
    @password = '???'    
    if params.include?('password')
      #-- A password has been supplied
      @password = params[:password].to_s
      @password_confirmation = params[:password_confirmation].to_s
      if @password == ''
        flash[:alert] += "Please choose a password<br>"
      elsif @password_confirmation == ''
        flash[:alert] += "Please enter your password a second time, to confirm<br>"
      elsif @password_confirmation != @password
        flash[:alert] += "The two passwords don't match<br>"
      end
    else
      #-- Create a password
      @password = ''
      3.times do
        conso = 'bcdfghkmnprstvw'[rand(15)]
        vowel = 'aeiouy'[rand(6)]
        @password += conso +  vowel
        @password += (1+rand(9)).to_s if rand(3) == 2
      end
    end
    
    @metamaps = Metamap.where(:global_default=>true)
    for metamap in @metamaps
      if params["meta_#{metamap.id}"].to_i == 0
        flash[:alert] += "Please choose your #{metamap.name}<br>"
      end
    end   
    if flash[:alert] != ''
      prepare_join
      render :action=>:joinform
      return
    end  
        
    @participant = Participant.find_by_email(@email) 
    if @participant
      # PARTICIPANT_STATUSES = ['unconfirmed','active','inactive','never-contact','disallowed']
      if @participant.status == 'active'
        flash[:alert] = "You already have an active account for #{@email}. Please log into that<br>"
        redirect_to '/participants/sign_in'
        return
      elsif @participant.status == 'inactive'
        flash[:alert] = "Your account is currently not active<br>"
        redirect_to '/participants/sign_in'
        return
      elsif @participant.status == 'never-contact' or @participant.status == 'disallowed'    
        flash[:alert] = "Your account has been closed<br>"
        redirect_to '/participants/sign_in'
        return
      elsif @participant.status == 'unconfirmed'  
        #-- We will update their existing unconfirmed account with what they just entered
        @participant.first_name = @first_name.strip
        @participant.last_name = @last_name.strip
        @participant.password = @password
        @participant.country_code = @country_code
        @participant.forum_email = 'daily'
        @participant.group_email = 'instant'
        @participant.subgroup_email = 'instant'
        @participant.private_email = 'instant'  
        @participant.status = 'unconfirmed'
        @participant.confirmation_token = Digest::MD5.hexdigest(Time.now.to_f.to_s + @email)
      else
        flash[:alert] = "You already have an account<br>"
        redirect_to '/participants/sign_in'
        return
      end    
    else
      @participant = Participant.new
      @participant.first_name = @first_name.strip
      @participant.last_name = @last_name.strip
      @participant.email = @email
      @participant.password = @password
      @participant.country_code = @country_code
      @participant.forum_email = 'daily'
      @participant.group_email = 'daily'
      @participant.subgroup_email = 'instant'
      @participant.private_email = 'instant'  
      @participant.status = 'unconfirmed'
      @participant.confirmation_token = Digest::MD5.hexdigest(Time.now.to_f.to_s + @email)
    end
 
    if flash[:alert] != ''
      prepare_join
      render :action=>:joinform
      return
    end  
    
    @participant.groups << @group if not @participant.groups.include?(@group)
    
    if not @participant.save!  
      flash[:alert] = "Sorry, there's some kind of database problem<br>"
      prepare_join
      render :action=>:joinform
      return
    end  

    # Also join Global Townhall Square
    group_participant = GroupParticipant.create(group_id: GLOBAL_GROUP_ID, participant_id: @participant.id, active: true, status: 'active')

    @participant.ensure_authentication_token!

    #-- Store their metamap category
    for metamap in @metamaps
      val = params["meta_#{metamap.id}"].to_i
      if val > 0
        mnp = MetamapNodeParticipant.where(:metamap_id=>metamap.id,:participant_id=>@participant.id).first
        if mnp
          mnp.metamap_node_id = val
          mnp.save
        else
          MetamapNodeParticipant.create(:metamap_id=>metamap.id,:metamap_node_id=>val,:participant_id=>@participant.id)
        end    
      end
    end

    if flash[:alert] != ''
      prepare_join
      render :action=>:joinform
      return        
    end
    
    # Pick an appropriate logo
    if @group.logo.exists?
      @logo = "//#{BASEDOMAIN}#{@group.logo.url}"
    else
      @logo = nil
    end

    if true
      dom = BASEDOMAIN
    elsif @group.shortname.to_s != ""
      dom = "#{@group.shortname}.#{ROOTDOMAIN}"
    else
      dom = BASEDOMAIN
    end
    
    #-- Send an e-mail to the member
    recipient = @participant
    cdata = {}
    cdata['item'] = @item
    cdata['recipient'] = @participant     
    cdata['participant'] = @participant 
    cdata['group'] = @group if @group
    cdata['group_logo'] = "//#{BASEDOMAIN}#{@group.logo.url}" if @group.logo.exists?
    cdata['logo'] = @logo if @logo
    cdata['password'] = @password
    cdata['confirmlink'] = "<a href=\"https://#{dom}/front/confirm?code=#{@participant.confirmation_token}&group_id=#{@group.id}\">https://#{dom}/front/confirm?code=#{@participant.confirmation_token}&group_id=#{@group.id}</a>"
    
    if @group.confirm_email_template.to_s != ''
      template = Liquid::Template.parse(@group.confirm_email_template)
      html_content = template.render(cdata)
    else    
      html_content = "<p>Welcome!</p><p>username: #{@participant.email}<br/>"
      html_content += "password: #{@password}<br/>" if @password != '???'
      
      html_content += "<br/>As the first step, please click this link, to confirm that it really was you who signed up, and to log in the first time:<br/><br/>"
      html_content += "https://#{dom}/front/confirm?code=#{@participant.confirmation_token}&group_id=#{@group.id}<br/><br/>"
      
      #html_content += "<br/>Click <a href=\"http://#{dom}/?auth_token=#{@participant.authentication_token}\">here</a> to log in the first time, or enter your username/password at http://#{dom}/<br/><br/>"
      
      html_content += "(If it wasn't you, just do nothing, and nothing further happens)<br/>"
      
      #html_content += "<br/>Then you'll be able to log in at any time at http://#{dom}/<br/>"
      html_content += "If you have lost your password: https://#{dom}/participants/password/new<br/>"   
      html_content += "</p>"
    end
  
    email = @participant.email
    msubject = "[#{@group.shortname}] Signup"
    email = SystemMailer.generic(SYSTEM_SENDER, @participant.email_address_with_name, msubject, html_content, cdata)

    begin
      logger.info("front#join delivering email to #{recipient.id}:#{recipient.name}")
      email.deliver
      message_id = email.message_id
    rescue Exception => e
      logger.info("front#join problem delivering email to #{recipient.id}:#{recipient.name}: #{e}")
    end

    if @group.confirm_template.to_s != ''
      template = Liquid::Template.parse(@group.confirm_template)
      @content = template.render(cdata)
    else
      @content = ""
      @content += "<p><img src=\"#{@logo}\"/></p>" if @logo
      #@content += "<p>Thank you! We've sent you an e-mail with your username and password. This e-mail also contains a confirmation link. Please click on that link to continue. This is simply to confirm that you really are you.</p>"
      @content += "<p align=\"center\"><big><b>#{@group.name}</b> Signup Success!</big></p>"
      @content += "<p>A confirmation email has been sent to the email address you provided. Please check your inbox. If you have not received the email within a few minutes, be sure to check your spam folder. You must click the link in that email to confirm it really was you who signed up.</p>"
    end
    
    cookies["g_#{@group.shortname}"] = { :value => "joined", :expires => Time.now + 30*3600}
    
    render :action=>:confirm, :layout=>'front'   
    
  end
  
  def autologin
    @participant = Participant.find_by_confirmation_token(params[:code])
    group_id,dialog_id = get_group_dialog_from_subdomain
    if @participant and @participant.status == 'active'
      #@participant.status = 'active'
      #@participant.save
      sign_in(:participant, @participant)
      @dialog = Dialog.find_by_id(dialog_id) if dialog_id > 0
      if @dialog
        redirect_to "/dialogs/#{@dialog.id}/slider"
      else
        redirect_to "/"
      end
    else
      redirect_to "/"
    end
  end
    
  def test
  end  
  
  def testajaxjson
    #-- Return some json, without needing login
    id = params[:somedata].to_i
    p = Participant.find_by_id(id)
    if p
      ret = {'name': p.name,'dummy': 'something'}
      render json: ret     
    else
      render json: {}   
    end
  end
  
  def api_fb_login_join
    #-- Ajax call from some external app
    #-- Assuming they've already logged into FB on the app
    #-- We get FB ID, name, email, and access token
    #-- If it matches an existing user with FB activated, we return InterMix ID and name and authentication_token
    #-- If existing user, but no FB authentication, add it, I suppose
    #-- If user doesn't exist, add them
    
    sign_out :participant if participant_signed_in?
    
    fb_uid = params[:fb_uid].to_i
    name = params[:name]
    email = params[:email]
    fb_access_token = params[:access_token]
    
    user_exists = false
    create_user = false
    
    ret = {'status': '', 'user_id': 0, 'username': '', 'name': '', 'auth_token': ''}
    
    auth = Authentication.where(uid: fb_uid).first
    if auth
      participant_id = auth.participant_id
      participant = Participant.find_by_id(participant_id)
      if participant
        if participant.email.downcase == email.downcase
          ret['status'] = "Found"
          ret['user_id'] = participant.id
          ret['username'] = participant.email
          ret['name'] = participant.name
          ret['auth_token'] = participant.authentication_token
          sign_in(:participant, participant)  
          user_exists = true   
        else
          ret['status'] = "Email doesn't match"    
        end
      else
        ret['status'] = "User not found"  
      end
    else
      ret['status'] = "No authentication found"  
      create_user = true
    end

    if create_user
      narr = name.split(' ')
      last_name = narr[narr.length-1]
      first_name = ''
      first_name = narr[0,narr.length-1].join(' ') if narr.length > 1
      
      
    end
    
    render json: ret 
  end
  
  def helptext
    #-- Return a piece of helptext for a tooltip
    @code = params[:code]
    help_text = HelpText.find_by_code(@code)
    if help_text
      render plain: help_text.text
    else
      render plain: "not found"
    end
  end 
  
  def helppage
    #-- Show a help text as a separate page
    @code = params[:code]
    @help_text = HelpText.find_by_code(@code)
    if @help_text and @help_text.text
      showtext = @help_text.text
    else
      showtext = "Help page not found"
    end
    render inline: showtext, layout: 'front'
  end  
  
  def youarehere
    @group_id = session[:group_id].to_i
    @group = Group.find_by_id(@group_id) if @group_id > 0
    @group_is_member = session[:group_is_member]
    @dialog_id = session[:dialog_id].to_i
    @dialog = Dialog.find_by_id(@dialog_id) if @dialog_id > 0
  end 
    
  protected
  
  def prepare_join
    @section = 'join'
    @email = params[:email]
    @countries = Geocountry.order(:extrasort,:name).select([:name,:iso])
    @meta = []
    @metamaps = Metamap.where(:global_default=>true)
    for metamap in @metamaps
      #m = OpenStruct.new
      m = {}
      m['id'] = metamap.id
      m['name'] = metamap.name
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
  end
  
  def prepare_djoin
    @section = 'join'
    @countries = Geocountry.order(:extrasort,:name).select([:name,:iso])
    @content = "<p>No discussion was recognized</p>"
    if @dialog.logo.exists?
      @logo = "//#{BASEDOMAIN}#{@dialog.logo.url}"
    else
      @logo = "https://voh.intermix.org/images/data/photos/7/67.jpg"
    end
    @meta = []
    #if @participant.country_code.to_s != ''
    #  @metro_areas = MetroArea.where(:country_code=>'US').order(:name).collect{|r| [r.name,r.id]}
    #else  
      @metro_areas = MetroArea.joins(:geocountry).order("geocountries.name,metro_areas.name").collect{|r| ["#{r.geocountry.name}: #{r.name}",r.id]}
    #end
    if @dialog
      metamaps = @dialog.metamaps
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
      @message = "" if not @message
      
      if @group
        if ! @dialog_group
          #-- Look up the dialog/group setting, which might contain a template
          @dialog_group = DialogGroup.where("group_id=#{@group.id} and dialog_id=#{@dialog.id}").first
        end
      else
        @dialog_group = nil 
      end
      
      if @comtag
        @community = Community.find_by_tagname(@comtag)
        if @community
          @comname = @community.fullname
        end
      else
        @community = nil  
      end
      
      @major_communities = Community.where(major: true).order(:fullname)
      @ungoals_communities = Community.where(ungoals: true).order(:fullname)
      @sustdev_communities = Community.where(sustdev: true).order(:fullname)
      
      cdata = {'group'=>@group, 'dialog'=>@dialog, 'dialog_group'=>@dialog_group, 'community'=>@community, 'countries'=>@countries, 'meta'=>@meta, 'message'=>@message, 'name'=>@name, 'first_name'=>@first_name, 'last_name'=>@last_name, 'country_code'=>@country_code, 'email'=>@email, 'subject'=>@subject, 'cookies'=>cookies, 'logo'=>@logo, 'metro_areas'=>@metro_areas}
      cdata['group_logo'] = "//#{BASEDOMAIN}#{@group.logo.url}" if @group.logo.exists?
      cdata['dialog_logo'] = "//#{BASEDOMAIN}#{@dialog.logo.url}" if @dialog.logo.exists?
      cdata['indigenous'] = @indigenous.to_i
      cdata['other_minority'] = @other_minority.to_i
      cdata['veteran'] = @veteran.to_i
      cdata['interfaith'] = @interfaith.to_i
      cdata['refugee'] = @refugee.to_i
      
      if @dialog_group and @dialog_group.signup_template.to_s != ''
        template_content = @dialog_group.signup_template
      elsif @dialog.signup_template.to_s != ''
        template_content = @dialog.signup_template
      else
        #@content = render_to_string(:partial=>'dialogjoinform_default',:layout=>false)
        template_content = render_to_string(:partial=>'dialogs/signup_default',:layout=>false)
      end
      template = Liquid::Template.parse(template_content)
      @content = template.render(cdata)
    end
    
  end
  
  def prepare_gjoin
    @section = 'join'
    @countries = Geocountry.order(:extrasort,:name).select([:name,:iso])
    @content = "<p>No group was recognized</p>"
    @logo = "//#{BASEDOMAIN}#{@group.logo.url}" if @group.logo.exists?
    @meta = []
    @metro_areas = MetroArea.joins(:geocountry).order("geocountries.name,metro_areas.name").collect{|r| ["#{r.geocountry.name}: #{r.name}",r.id]}
    metamaps = @group.metamaps
    for metamap in metamaps
      #m = OpenStruct.new
      m = {}
      m['id'] = metamap.id
      m['name'] = metamap.name
      m['val'] = params["meta_#{metamap.id}"].to_i
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
        
    cdata = {'group'=>@group, 'name'=>@name, 'first_name'=>@first_name, 'last_name'=>@last_name, 'country_code'=>@country_code, 'countries'=>@countries, 'meta'=>@meta, 'email'=>@email, 'cookies'=>cookies, 'logo'=>@logo, 'metro_areas'=>@metro_areas}
    cdata['group_logo'] = "//#{BASEDOMAIN}#{@group.logo.url}" if @group.logo.exists?
    if @group and @group.signup_template.to_s != ''
      template_content = @group.signup_template
    else
      #@content = render_to_string(:partial=>'groupjoinform_default',:layout=>false)
      template_content = render_to_string(:partial=>'groups/signup_default',:layout=>false)
    end
    template = Liquid::Template.parse(template_content)
    @content = template.render(cdata)
  end
    
end
