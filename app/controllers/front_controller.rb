# encoding: utf-8

#require 'ostruct'

class FrontController < ApplicationController

	layout "front"
	
	include Magick
  
  def index
    @section = 'home'
    group_id,dialog_id = get_group_dialog_from_subdomain
    @content = ""
    cdata = {'cookies'=>cookies}
    if dialog_id.to_i > 0
      @dialog = Dialog.find_by_id(dialog_id)
      cdata['dialog'] = @dialog if @dialog
      if participant_signed_in? and @dialog.member_template.to_s != ''
        desc = Liquid::Template.parse(@dialog.member_template).render(cdata)
      elsif @dialog.front_template.to_s != ''
        desc = Liquid::Template.parse(@dialog.front_template).render(cdata)
      else
        desc = "<h2>#{@dialog.name}</h2><div>#{@dialog.description}</div>\n"
      end
      @content += "<div>#{desc}</div>"
    elsif group_id.to_i > 0
      @group = Group.find_by_id(group_id)
      cdata['group'] = @group if @group
      if participant_signed_in? and @group.member_template.to_s != ''
        desc = Liquid::Template.parse(@group.member_template).render(cdata)
      elsif @group.front_template.to_s != ''
        desc = Liquid::Template.parse(@group.front_template).render(cdata)
      else
        desc = "<h2>#{@group.name}</h2><div>#{@group.description}</div>\n"
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
    @photos = Photo.scoped
    @photos = @photos.where(:participant_id=>@participant_id) if @participant_id > 0
    @photos = @photos.all
    @picdir = "#{DATADIR}/photos"
    @picurl = "/images/data/photos"
    update_last_url
  end  
  
  def photolist
    photos
    render :partial=>'photolist', :layout=>false
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
    first_name = narr[0,narr.length-1].join(' ')
    password = 'test'
    
    @participant = Participant.find_by_email(@email) 
    if @participant 
      flash[:notice] = "You seem to already have an account, so we posted it to that<br>"
    else
      @participant = Participant.new
      @participant.first_name = first_name
      @participant.last_name = last_name
      @participant.email = @email
      @participant.password = password
      #@participant.country_code = 'US' if state.to_s != ''
      @participant.forum_email = 'never'
      @participant.group_email = 'never'
      @participant.private_email = 'instant'  
      @participant.status = 'inactive'
      if not @participant.save!  
        flash[:alert] = "Sorry, there's some kind of database problem<br>"
        render :action=>:instantjoinform, :layout=>'blank'
        return
      end  
    end
    
    @participant.groups << @group
 
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
    @group_id,@dialog_id = get_group_dialog_from_subdomain    
    @dialog_id = params[:dialog_id].to_i if not @dialog_id
    @dialog_id = params[:id].to_i if not @dialog_id or @dialog_id == 0
    @group_id = params[:group_id].to_i if not @group_id or @group_id == 0
    @dialog = Dialog.find_by_id(@dialog_id)
    if @dialog and @group_id == 0
      @group_id = @dialog.group_id.to_i
    end 
    @group = Group.find_by_id(@group_id)
        
    if @dialog and current_participant and participant_signed_in?
      redirect_to "http://#{@dialog.shortname}.#{ROOTDOMAIN}/"
      return
    elsif @group and current_participant and participant_signed_in?
      redirect_to "http://#{@group.shortname}.#{ROOTDOMAIN}/"
      return
    end
    
    prepare_djoin
    
    render :action=>:dialogjoinform, :layout=>'blank'
  end
  
  def dialogjoin
    #-- What the discussion join form posts to
    @dialog_id = params[:dialog_id].to_i
    @group_id = params[:group_id].to_i
    logger.info("Front#dialogjoin dialog:#{@dialog_id} group:#{@group_id}")
    
    @dialog = Dialog.find_by_id(@dialog_id)
    if @dialog and @group_id == 0
      @group_id = @dialog.group_id.to_i
    end 
    @group = Group.find_by_id(@group_id)
    
    if @group and @dialog
      #-- Look up the dialog/group setting, which might contain a template
      @dialog_group = DialogGroup.where("group_id=#{@group.id} and dialog_id=#{@dialog.id}").first
    end
    
    @subject = params[:subject].to_s
    @message = params[:message].to_s
    @name = params[:name].to_s
    @email = params[:email].to_s
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
      render :action=>:dialogjoinform, :layout=>'blank'
      return
    end  

    if @message.to_s == '' and ((@dialog and @dialog.settings_with_period["required_message"]) or @subject.to_s != '')
      flash[:alert] += "Please include at least a short message<br>"
    elsif @dialog and @dialog.settings_with_period["max_characters"].to_i > 0 and @message.length > @dialog.settings_with_period["max_characters"]  
      flash[:alert] += "The maximum message length is #{@dialog.max_characters} characters<br>"
    elsif @dialog.required_subject and @subject.to_s == '' and @message.gsub(/<\/?[^>]*>/, "").strip != ''
      flash[:alert] += "Please choose a subject line<br>"
    elsif @subject != '' and @subject.length > 48
      flash[:alert] += "Maximum 48 characters for the subject line, please<br>"        
    end
    if @name == ''
      flash[:alert] += "What's your name?<br>"
    end  
    if @email == ''
      flash[:alert] += "Please type in your e-mail address as well<br>"
    elsif not @email =~ /^[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,4}$/
      flash[:alert] += "That doesn't look like a valid e-mail address<br>"
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
      render :action=>:dialogjoinform, :layout=>'blank'
      return
    end  

    narr = @name.split(' ')
    last_name = narr[narr.length-1]
    first_name = narr[0,narr.length-1].join(' ')
    password = '???'    
        
    @participant = Participant.find_by_email(@email) 
    previous_messages = 0
    if @participant 
      previous_messages = Item.where("posted_by=? and dialog_id=?",@participant.id,@dialog.id).count
      if @dialog.max_messages > 0 and @message.length > 0 and previous_messages >= @dialog.max_messages
        flash[:alert] = "You have already posted a message to this discussion before.<br>You can see the messages when you log in at: http://#{@dialog.shortname}.#{ROOTDOMAIN}/<br>"
      elsif @message.length == 0
        flash[:notice] = "You already have an account<br>"
      else
        flash[:notice] = "You seem to already have an account, so we posted it to that<br>"
      end
    else
      #-- Create a password
      password = ''
      3.times do
        conso = 'bcdfghkmnprstvw'[rand(15)]
        vowel = 'aeiouy'[rand(6)]
        password += conso +  vowel
        password += (1+rand(9)).to_s if rand(3) == 2
      end
      @participant = Participant.new
      @participant.first_name = first_name
      @participant.last_name = last_name
      @participant.email = @email
      @participant.password = password
      #@participant.country_code = 'US' if state.to_s != ''
      @participant.forum_email = 'never'
      @participant.group_email = 'never'
      @participant.private_email = 'instant'  
      @participant.status = 'unconfirmed'
      @participant.confirmation_token = Digest::MD5.hexdigest(Time.now.to_f.to_s + @email)
    end
    
    @participant.groups << @group if not @participant.groups.include?(@group)
    
    if not @participant.save!  
      flash[:alert] = "Sorry, there's some kind of database problem<br>"
      render :action=>:dialogjoinform, :layout=>'blank'
      return
    end  

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
      render :action=>:dialogjoinform, :layout=>'blank'
      return        
    end
    
    if @message.gsub(/<\/?[^>]*>/, "").strip == "Dear Mr. Secretary General,"
      @message = ""
    end
 
    if @message != '' or @subject != ''
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
      @logo = "http://#{BASEDOMAIN}#{@dialog.logo.url}"
    elsif @group.logo.exists?
      @logo = "http://#{BASEDOMAIN}#{@group.logo.url}"
    else
      @logo = nil
    end
    logger.info("front#dialogjoin @logo set to #{@logo}")

    if @dialog.shortname.to_s != "" and @group.shortname.to_s != ""
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
    cdata['password'] = password
    cdata['confirmlink'] = "http://#{dom}/front/confirm?code=#{@participant.confirmation_token}&dialog_id=#{@dialog.id}"
    
    if @dialog_group and @dialog_group.confirm_email_template.to_s != ''
      template = Liquid::Template.parse(@dialog_group.confirm_email_template)
      html_content = template.render(cdata)
    elsif @dialog.confirm_email_template.to_s != ''
      template = Liquid::Template.parse(@dialog.confirm_email_template)
      html_content = template.render(cdata)
    else    
      html_content = "<p>Welcome!</p><p>username: #{@participant.email}<br/>"
      html_content += "password: #{password}<br/>" if password != '???'
      
      html_content += "<br/>As the first step, please click this link, to confirm that it really was you who signed up, and to log in the first time:<br/><br/>"
      html_content += "http://#{dom}/front/confirm?code=#{@participant.confirmation_token}&dialog_id=#{@dialog.id}<br/><br/>"
      html_content += "(If it wasn't you, just do nothing, and nothing further happens)<br/>"
      
      html_content += "<br/>Then you'll be able to log in at any time at http://#{dom}/<br/>"
      html_content += "If you have lost your password: http://#{dom}/participants/password/new<br/>"   
      html_content += "</p>"
    end
  
    email = @participant.email
    msubject = "[#{@dialog.shortname}] Signup"
    email = SystemMailer.generic(SYSTEM_SENDER, @participant.email_address_with_name, msubject, html_content, cdata)

    begin
      logger.info("Item#emailit delivering email to #{recipient.id}:#{recipient.name}")
      email.deliver
      message_id = email.message_id
    rescue
      logger.info("Item#emailit problem delivering email to #{recipient.id}:#{recipient.name}")
    end

    if @dialog_group and @dialog_group.confirm_template.to_s != ''
      template = Liquid::Template.parse(@dialog_group.confirm_template)
      @content = template.render(cdata)
    elsif @dialog.confirm_template.to_s != ''
      template = Liquid::Template.parse(@dialog.confirm_template)
      @content = template.render(cdata)
    else
      @content = ""
      @content += "<p><img src=\"#{@logo}\"/></p>" if @logo
      @content += "<p>Thank you! We've sent you an e-mail with your username and password. This e-mail also contains a confirmation link. Please click on that link to continue. This is simply to confirm that you really are you.</p>"
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
        
    if @dialog and current_participant and participant_signed_in?
      redirect_to "http://#{@dialog.shortname}.#{ROOTDOMAIN}/"
      return
    elsif @group and current_participant and participant_signed_in?
      redirect_to "http://#{@group.shortname}.#{ROOTDOMAIN}/"
      return
    end
    
    prepare_gjoin
    
    render :action=>:groupjoinform, :layout=>'blank'
  end  
    
  def groupjoin
    #-- What the group join form posts to
    @group_id = params[:group_id].to_i
    logger.info("Front#groupjoin group:#{@group_id}")
    
    @group = Group.find_by_id(@group_id)

    @name = params[:name].to_s
    @email = params[:email].to_s
    tempfilepath = ''
    
    flash[:notice] = ''
    flash[:alert] = '' 
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
      prepare_gjoin
      render :action=>:groupjoinform, :layout=>'blank'
      return
    end  

    if @name == ''
      flash[:alert] += "What's your name?<br>"
    end  
    if @email == ''
      flash[:alert] += "Please type in your e-mail address as well<br>"
    elsif not @email =~ /^[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,4}$/
      flash[:alert] += "That doesn't look like a valid e-mail address<br>"
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
      render :action=>:groupjoinform, :layout=>'blank'
      return
    end  

    narr = @name.split(' ')
    last_name = narr[narr.length-1]
    first_name = narr[0,narr.length-1].join(' ')
    password = '???'    
        
    @participant = Participant.find_by_email(@email) 
    previous_messages = 0
    if @participant 
      flash[:notice] = "You seem to already have an account. Please log into that.<br>"
    else
      #-- Create a password
      password = ''
      3.times do
        conso = 'bcdfghkmnprstvw'[rand(15)]
        vowel = 'aeiouy'[rand(6)]
        password += conso +  vowel
        password += (1+rand(9)).to_s if rand(3) == 2
      end
      @participant = Participant.new
      @participant.first_name = first_name
      @participant.last_name = last_name
      @participant.email = @email
      @participant.password = password
      #@participant.country_code = 'US' if state.to_s != ''
      @participant.forum_email = 'never'
      @participant.group_email = 'never'
      @participant.private_email = 'instant'  
      @participant.status = 'unconfirmed'
      @participant.confirmation_token = Digest::MD5.hexdigest(Time.now.to_f.to_s + @email)
    end
    
    @participant.groups << @group if not @participant.groups.include?(@group)
    
    if not @participant.save!  
      flash[:alert] = "Sorry, there's some kind of database problem<br>"
      render :action=>:groupjoinform, :layout=>'blank'
      return
    end  

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
      render :action=>:groupjoinform, :layout=>'blank'
      return        
    end
    
    # Pick an appropriate logo
    if @group.logo.exists?
      @logo = "http://#{BASEDOMAIN}#{@group.logo.url}"
    else
      @logo = nil
    end
    logger.info("front#groupjoin @logo set to #{@logo}")

    if @group.shortname.to_s != ""
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
    cdata['logo'] = @logo if @logo
    cdata['password'] = password
    cdata['confirmlink'] = "http://#{dom}/front/confirm?code=#{@participant.confirmation_token}&group_id=#{@group.id}"
    
    if @group.confirm_email_template.to_s != ''
      template = Liquid::Template.parse(@group.confirm_email_template)
      html_content = template.render(cdata)
    else    
      html_content = "<p>Welcome!</p><p>username: #{@participant.email}<br/>"
      html_content += "password: #{password}<br/>" if password != '???'
      
      html_content += "<br/>As the first step, please click this link, to confirm that it really was you who signed up, and to log in the first time:<br/><br/>"
      html_content += "http://#{dom}/front/confirm?code=#{@participant.confirmation_token}&group_id=#{@group.id}<br/><br/>"
      html_content += "(If it wasn't you, just do nothing, and nothing further happens)<br/>"
      
      html_content += "<br/>Then you'll be able to log in at any time at http://#{dom}/<br/>"
      html_content += "If you have lost your password: http://#{dom}/participants/password/new<br/>"   
      html_content += "</p>"
    end
  
    email = @participant.email
    msubject = "[#{@group.shortname}] Signup"
    email = SystemMailer.generic(SYSTEM_SENDER, @participant.email_address_with_name, msubject, html_content, cdata)

    begin
      logger.info("gront#groupjoin delivering email to #{recipient.id}:#{recipient.name}")
      email.deliver
      message_id = email.message_id
    rescue
      logger.info("front#groupjoin problem delivering email to #{recipient.id}:#{recipient.name}")
    end

    if @group.confirm_template.to_s != ''
      template = Liquid::Template.parse(@group.confirm_template)
      @content = template.render(cdata)
    else
      @content = ""
      @content += "<p><img src=\"#{@logo}\"/></p>" if @logo
      @content += "<p>Thank you! We've sent you an e-mail with your username and password. This e-mail also contains a confirmation link. Please click on that link to continue. This is simply to confirm that you really are you.</p>"
    end
    
    cookies["g_#{@group.shortname}"] = { :value => "joined", :expires => Time.now + 30*3600}
    
    render :action=>:confirm, :layout=>'front'
  end  
    
  def confirm
    #-- Confirmation link in e-mail, when signing up
    @participant = Participant.find_by_confirmation_token(params[:code])
    @content = ""
    @content += "<p><img src=\"#{@logo}\"/></p>" if @logo
    if @participant
      @participant.status = 'active'
      @participant.save
      sign_in(:participant, @participant)
      group_id,dialog_id = get_group_dialog_from_subdomain
      dialog_id = params[:dialog_id].to_i if dialog_id.to_i == 0
      group_id = params[:group_id].to_i if group_id.to_i == 0
      @dialog = Dialog.find_by_id(dialog_id) if dialog_id > 0
      @group = Group.find_by_id(group_id) if group_id > 0
      if @dialog
        @content += "<p>Thank you for confirming!<br><br>You are already logged in.<br><br>Click on <a href=\"http://#{@dialog.shortname}.#{ROOTDOMAIN}/dialogs/#{@dialog.id}/forum\">Discussion</a> on the left to see the messages.<br><br>Bookmark this link so you can come back later:<br><br><a href=\"http://#{@dialog.shortname}.#{ROOTDOMAIN}/\">http://#{@dialog.shortname}.#{ROOTDOMAIN}/</a>.</p>"
        session[:new_signup] = 1
        redirect_to "/dialogs/#{@dialog.id}/forum"
        return
      elsif @dialog  
        @content += "<p>Thank you for confirming! You can now go to: <a href=\"http://#{BASEDOMAIN}/dialogs/#{@dialog.id}/forum\">http://#{BASEDOMAIN}/dialogs/#{@dialog.id}/forum</a> to see the messages. You are already logged in.</p>"
      elsif @group  
        @content += "<p>Thank you for confirming! You can now go to: <a href=\"http://#{BASEDOMAIN}/groups/#{@group.id}/forum\">http://#{BASEDOMAIN}/groups/#{@group.id}/forum</a> to see the messages. You are already logged in.</p>"
      else
        @content += "<p>Thank you for confirming! You can now go to: <a href=\"http://#{BASEDOMAIN}/\">http://#{BASEDOMAIN}/</a>. You are already logged in.</p>"
      end
    else
      @content += "not recognized"
    end
    
    render :action=>:confirm, :layout=>'front'
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

    @email = params[:email].to_s
    @first_name = params[:first_name].to_s
    @last_name = params[:last_name].to_s
    @password = params[:password].to_s
    @password_confirmation = params[:password_confirmation].to_s
    @group_id = params[:group_id].to_i
    
    #-- Do a bit of validation
    flash[:alert] = ''
    if @first_name == '' and @last_name == ''
      flash[:alert] += "Please enter your name<br>"
    elsif @first_name == ''
      flash[:alert] += "Please enter your first name<br>"
    elsif @last_name == ''
      flash[:alert] += "Please enter your last name<br>"
    end
    if @email == ''
      flash[:alert] += "Please type in your e-mail address as well<br>"
    elsif not @email =~ /^[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,4}$/
      flash[:alert] += "That doesn't look like a valid e-mail address<br>"
    end  
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
    if @password == ''
      flash[:alert] += "Please choose a password<br>"
    elsif @password_confirmation == ''
      flash[:alert] += "Please enter your password a second time, to confirm<br>"
    elsif @password_confirmation != @password
      flash[:alert] += "The two passwords don't match<br>"
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
      flash[:alert] = "You seem to already have an account for #{@email}. Please log into that.<br>"
    else
      @participant = Participant.new
      @participant.first_name = @first_name
      @participant.last_name = @last_name
      @participant.email = @email
      @participant.password = @password
      #@participant.country_code = 'US' if state.to_s != ''
      @participant.forum_email = 'never'
      @participant.group_email = 'never'
      @participant.private_email = 'instant'  
      @participant.status = 'unconfirmed'
      @participant.confirmation_token = Digest::MD5.hexdigest(Time.now.to_f.to_s + @email)
    end
    
    @participant.groups << @group if not @participant.groups.include?(@group)
    
    if not @participant.save!  
      flash[:alert] = "Sorry, there's some kind of database problem<br>"
      prepare_join
      render :action=>:joinform
      return
    end  

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
      @logo = "http://#{BASEDOMAIN}#{@group.logo.url}"
    else
      @logo = nil
    end

    if @group.shortname.to_s != ""
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
    cdata['logo'] = @logo if @logo
    cdata['password'] = @password
    cdata['confirmlink'] = "http://#{dom}/front/confirm?code=#{@participant.confirmation_token}&group_id=#{@group.id}"
    
    if @group.confirm_email_template.to_s != ''
      template = Liquid::Template.parse(@group.confirm_email_template)
      html_content = template.render(cdata)
    else    
      html_content = "<p>Welcome!</p><p>username: #{@participant.email}<br/>"
      html_content += "password: #{@password}<br/>" if @password != '???'
      
      html_content += "<br/>As the first step, please click this link, to confirm that it really was you who signed up, and to log in the first time:<br/><br/>"
      html_content += "http://#{dom}/front/confirm?code=#{@participant.confirmation_token}&group_id=#{@group.id}<br/><br/>"
      html_content += "(If it wasn't you, just do nothing, and nothing further happens)<br/>"
      
      html_content += "<br/>Then you'll be able to log in at any time at http://#{dom}/<br/>"
      html_content += "If you have lost your password: http://#{dom}/participants/password/new<br/>"   
      html_content += "</p>"
    end
  
    email = @participant.email
    msubject = "[#{@group.shortname}] Signup"
    email = SystemMailer.generic(SYSTEM_SENDER, @participant.email_address_with_name, msubject, html_content, cdata)

    begin
      logger.info("front#join delivering email to #{recipient.id}:#{recipient.name}")
      email.deliver
      message_id = email.message_id
    rescue
      logger.info("front#join problem delivering email to #{recipient.id}:#{recipient.name}")
    end

    if @group.confirm_template.to_s != ''
      template = Liquid::Template.parse(@group.confirm_template)
      @content = template.render(cdata)
    else
      @content = ""
      @content += "<p><img src=\"#{@logo}\"/></p>" if @logo
      @content += "<p>Thank you! We've sent you an e-mail with your username and password. This e-mail also contains a confirmation link. Please click on that link to continue. This is simply to confirm that you really are you.</p>"
    end
    
    cookies["g_#{@group.shortname}"] = { :value => "joined", :expires => Time.now + 30*3600}
    
    render :action=>:confirm, :layout=>'front'   
    
  end
  
  def autologin
    @participant = Participant.find_by_confirmation_token(params[:code])
    group_id,dialog_id = get_group_dialog_from_subdomain
    if @participant and @participant.status == 'active'
      @participant.status = 'active'
      @participant.save
      sign_in(:participant, @participant)
      @dialog = Dialog.find_by_id(dialog_id) if dialog_id > 0
      if @dialog
        redirect_to "/dialogs/#{@dialog.id}/forum"
      else
        redirect_to "/"
      end
    else
      redirect_to "/"
    end
  end
    
  def test
  end    
  
  protected
  
  def prepare_join
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
    @content = "<p>No discussion was recognized</p>"
    meta = []
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
        meta << m
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
      
      cdata = {'group'=>@group, 'dialog'=>@dialog, 'dialog_group'=>@dialog_group, 'meta'=>meta, 'message'=>@message, 'name'=>@name, 'email'=>@email, 'subject'=>@subject, 'cookies'=>cookies}
      if @dialog_group and @dialog_group.signup_template.to_s != ''
        template = Liquid::Template.parse(@dialog_group.signup_template)
        @content = template.render(cdata)
      elsif @dialog.signup_template.to_s != ''
        template = Liquid::Template.parse(@dialog.signup_template)
        @content = template.render(cdata)
      else
        @content = render_to_string(:partial=>'dialogjoinform_default',:layout=>false)
      end
    end
  end
  
  def prepare_gjoin
    @content = "<p>No group was recognized</p>"
    @meta = []
    metamaps = @group.metamaps
    for metamap in metamaps
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
        
    cdata = {'group'=>@group, 'name'=>@name, 'meta'=>@meta, 'email'=>@email, 'cookies'=>cookies}
    if @group and @group.signup_template.to_s != ''
      template = Liquid::Template.parse(@group.signup_template)
      @content = template.render(cdata)
    else
      @content = render_to_string(:partial=>'groupjoinform_default',:layout=>false)
    end
  end
    
end
