# encoding: utf-8

class ApplicationController < ActionController::Base
  protect_from_forgery  

	layout "front"

  helper_method :sanitizethis, :get_group_dialog_from_subdomain, :get_oembed
  
  #after_filter :store_location

  before_action :store_user_location!, if: :storable_location?

  #def store_location
    # store last url, particularly so we can set it after login
    # https://stackoverflow.com/questions/15944159/devise-redirect-back-to-the-original-location-after-sign-in-or-sign-up
    #session[:previous_url] = request.fullpath unless request.fullpath =~ /\/users/
  #  session[:previous_url] = request.fullpath
  #  if params[:comtag].to_s != ''
  #    session[:previous_comtag] = params[:comtag]
  #  end
  #  logger.info("application#store_location previous_url:#{session[:previous_url]} previous_comtag:#{session[:previous_comtag]}")
  #end

  def getadmin1s
    #-- Get the state/region entries for a certain country, for a select box
    @country_code = params[:country_code].to_s
    if @country_code == ''  
      res = [{:val=>0, :txt=>''}]
    else
      res = [{:val=>0, :txt=>''}] + Geoadmin1.where("country_code='#{@country_code}' and admin1_code!='00'").order("name").collect {|r| {:val=>r.admin1uniq,:txt=>r.name}}
    end          
    render :layout=>false, :text => res.to_json
  end  

  def getadmin2s
    #-- Get the county/department entries for a certain state/region, for a select box
    #-- We either get everything in a certain country or everything in an admin1 region
    @country_code = params[:country_code].to_s
    @admin1uniq = params[:admin1uniq].to_s
    if @admin1uniq == '' and @country_code == '' 
      res = [{:val=>0, :txt=>''}]
    elsif @admin1uniq != ""
      res = [{:val=>0, :txt=>''}] + Geoadmin2.where("admin1uniq='#{@admin1uniq}'").order("name").collect {|r| {:val=>r.admin2uniq,:txt=>r.name}}
    elsif @country_code != ""
      res = [{:val=>0, :txt=>''}] + Geoadmin2.where("country_code='#{@country_code}'").order("name").collect {|r| {:val=>r.admin2uniq,:txt=>r.name}}
    end
    render :layout=>false, :text => res.to_json
  end  
  
  def getmetro
    #-- Get the metro areas for a certain country, for a select box
    @country_code = params[:country_code].to_s
    if @country_code == ''  
      res = [{:val=>0, :txt=>''}]
    else
      res = [{:val=>0, :txt=>''}] + MetroArea.where(:country_code=>@country_code).order("population desc").collect {|r| {:val=>r.id,:txt=>r.name}}
    end          
    render :layout=>false, :text => res.to_json
  end  
  
  def setsess
    if participant_signed_in?
      if params[:fullmenu].to_s != ''
        if params[:fullmenu] == 'false'
          session[:fullmenu] = false
        else
          session[:fullmenu] = true
        end
      end
    end
    render plain: "ok"
  end
      
  protected

	def set_headers
		headers["Content-Type"] = "text/html; charset=utf-8" 
    headers["P3P"] = 'CP="IDC DSP COR CUR ADMa OUR STP ONL UNI NAV CNT STA"'
	end
  
  def urlencode(str)
	  #-- This is a urlencode that works according to RFC1738, rather than like PHP's urlencode or CGI.escape
	  #-- i.e. a space is %20 rather than a +
	  # http://www.elctech.com/articles/will-the-real-urlencode-please-stand-uphttp://www.elctech.com/articles/will-the-real-urlencode-please-stand-up
    str.gsub(/[^a-zA-Z0-9_\.\-]/n) {|s| sprintf('%%%02x', s[0]) }
  end
  
  def get_oembed(url)
    #-- Look up a media link and return the fields
    #-- https://oembed.com/#section7
    
    return {} if not url or url.to_s == ''
    
    host = URI.parse(url).host
    domain = host.split('.').last(2).join('.')
    
    url_enc = CGI.escape(url)
    
    
    results = {}
    
    if domain == 'youtube.com' or domain == 'youtu.be'
      api_url = "http://www.youtube.com/oembed?url=#{url_enc}&format=json"
    elsif domain == 'dailymotion.com'
      api_url = "http://www.dailymotion.com/services/oembed?url=#{url_enc}"
    elsif domain == "hulu.com"  
      api_url = "http://www.hulu.com/api/oembed.xml?url=#{url_enc}"
    elsif domain == 'ted.com'
      api_url = "http://www.ted.com/talks/oembed.xml?url=#{url_enc}"
    elsif domain == 'ustream.com'
      api_url = "http://www.ustream.tv/oembed?url=#{url_enc}"
    elsif domain == 'vevo.com'
      api_url = "https://www.vevo.com/oembed?url=#{url_enc}"
    elsif domain == 'vimeo.com'
      api_url = "https://vimeo.com/api/oembed.json?url=#{url_enc}"
    elsif domain == 'giphy.com'
      api_url = "http://giphy.com/services/oembed?url=#{url_enc}"
    elsif domain == 'soundcloud.com'
      api_url = "https://soundcloud.com/oembed?url=#{url_enc}&format=json"
    elsif domain == 'spotify.com'
      api_url = "https://embed.spotify.com/oembed/?url=#{url_enc}"
    end  

    logger.info("application#get_oembed domain:#{domain} url:#{api_url}")

    begin
      results = JSON.load(open(api_url))
    rescue
      results = {}
    end
    
    logger.info("application#get_oembed "+results.inspect)
    #{"version"=>"1.0", "provider_name"=>"YouTube", "author_url"=>"https://www.youtube.com/channel/UCLIMHPyCkK36zrFlphKV8-Q", "thumbnail_url"=>"https://i.ytimg.com/vi/zwl-PpuIxWo/hqdefault.jpg", "author_name"=>"JohnStax", "provider_url"=>"https://www.youtube.com/", "type"=>"video", "height"=>270, "width"=>480, "title"=>"Checking out the worlds cheapest Supercars at Copart Auto Auction. lamborghini  samcrac", "thumbnail_width"=>480, "html"=>"<iframe width=\"480\" height=\"270\" src=\"https://www.youtube.com/embed/zwl-PpuIxWo?feature=oembed\" frameborder=\"0\" allow=\"autoplay; encrypted-media\" allowfullscreen></iframe>", "thumbnail_height"=>360}

    return results

    #embedly_api = Embedly::API.new key: EMBEDLY_API_KEY, user_agent: 'Mozilla/5.0 (compatible; mytestapp/1.0; my@email.com)'
    #begin
    #  results = embedly_api.oembed :url => url
    #  if results.length > 0
    #    results[0]
    #  else
    #    {}
    #  end  
    #rescue
    #  {}
    #end    
  end
  
  def emailit(toemail, subject, message)
    #-- E-mail a message that isn't associated with a message or item
    
    @cdata = {}

    #@cdata['attachments'] = @attachments
      
    email = SystemMailer.generic(subject, message, toemail, @cdata)
    
    begin
      logger.info("application#emailit delivering email to #{toemail}")
      email.deliver
    rescue
    end
      
    return true
    
  end  
  
  def sanitizethis(sometext)
    Sanitize.clean(sometext.force_encoding("UTF-8"), 
      :elements => ['a', 'p', 'br', 'u', 'b', 'em', 'strong', 'ul', 'ol', 'li', 'h1', 'h2', 'h3','table','tr','tbody','td','img'],
      :attributes => {'a' => ['href', 'title', 'target'], 'img' => ['src', 'alt', 'width', 'height', 'align', 'vspace', 'hspace', 'style']},
      :protocols => {'a' => {'href' => ['http', 'https', 'mailto', :relative]}, 'img' => {'src'  => ['http', 'https', :relative]} },
      :css => {
          :properties => ['width','height','float','border-width','border-style','margin']
      },
      :allow_comments => false,
      :output => :html
    )
  end

  def update_last_url(url='')
    #-- Record where the user last was, so they can get back there next time they log in
    url = request.env['PATH_INFO'] if url == ''
    if current_participant
      current_participant.last_url = url
      current_participant.save()
    end  
  end  
    
  def after_sign_in_path_for(resource_or_scope)
    #-- Overrides the devise function to go to our remembered URL after logging in
    logger.info("application#after_sign_in_path_for")
    
    #-- Also do a few other things we need to do when somebody logs in
    
    session[:cur_prefix] = ''
    session[:cur_baseurl] = ''
    session[:group_id] = 0
    session[:group_name] = ''
    session[:group_prefix] = ''
    session[:dialog_id] = 0
    session[:dialog_name] = ''
    session[:dialog_prefix] = ''
    
    if current_participant.status != 'active'
      flash[:alert] = "Your account is not active"
      flash.now[:alert] = "Your account is not active"
      #auth.logout
      sign_out :participant 
      '/'
      return
    end  
    #if current_participant.status == 'unconfirmed'
      #  #-- If they logged in, but are unconfirmed, it is probably the first time
      #  current_participant.status = 'active'
      #  current_participant.save
      #  session[:new_signup] = 1
    #end
    
    #-- This will check if required fields have been entered, and remember it, so we will show only their profile if we're missing something.
    session[:has_required] = current_participant.has_required
    
    group_id,dialog_id = get_group_dialog_from_subdomain
    return if not group_id and not dialog_id
    group_id,dialog_id = check_group_and_dialog if session[:group_id].to_i == 0 and session[:dialog_id].to_i == 0

    if session[:dialog_prefix] != '' and session[:group_prefix] != ''
      session[:cur_prefix] = session[:dialog_prefix] + '.' + session[:group_prefix]
    elsif session[:group_prefix] != ''
      session[:cur_prefix] = session[:group_prefix]
    elsif session[:dialog_prefix] != ''
      session[:cur_prefix] = session[:dialog_prefix]
    end
    
    if session[:cur_prefix] != ''
      session[:cur_baseurl] = "https://" + session[:cur_prefix] + "." + ROOTDOMAIN    
    else
      session[:cur_baseurl] = "https://" + BASEDOMAIN    
    end
    logger.info("application#after_sign_in_path_for cur_baseurl:#{session[:cur_baseurl]}")

    #-- See if they're a moderator of a group, or a hub admin. Only those can add new discussions.
    groupsmodof = GroupParticipant.where("participant_id=#{current_participant.id} and moderator=1")
    session[:is_group_moderator] = (groupsmodof.length > 0)
    hubadmins = HubAdmin.where("participant_id=#{current_participant.id} and active=1")
    session[:is_hub_admin] = (hubadmins.length > 0)
    session[:is_sysadmin] = current_participant.sysadmin
    session[:is_anyadmin] = (session[:is_group_moderator] or session[:is_hub_admin] or session[:is_sysadmin])
  
    #if dialog_id.to_i>0 and group_id.to_i > 0
    if group_id.to_i > 0
      @group = Group.find_by_id(group_id) if not @group
      #-- Check if they're a member of the group. If not, join them
      #if @group.openness == 'open'
        # No longer caring about group settings
        group_participant = GroupParticipant.where("participant_id=#{current_participant.id} and group_id=#{group_id}").first
        if group_participant
          session[:group_is_member] = true
        else
          group_participant = GroupParticipant.new(:group_id=>group_id,:participant_id=>current_participant.id)
          group_participant.active = true
          group_participant.status = 'active'
          group_participant.save
          session[:group_is_member] = true
        end
      #end
    end  
    
    if current_participant.fb_uid.to_i >0 and not current_participant.picture.exists?
      #-- If they don't have a picture set, and they have a facebook account, get it from there
      url = "https://graph.facebook.com/#{current_participant.fb_uid}/picture?type=large"
      current_participant.picture = URI.parse(url).open
      current_participant.save!
    end
  
    # Return the URL they will be sent to
    if params[:fb_sig_in_iframe].to_i == 1
      session[:cur_baseurl] + '/fbapp'
    elsif not session[:has_required]
      #session[:cur_baseurl] + '/me/profile/edit#settings'
      session[:cur_baseurl] + '/me/profile/meta'
    elsif true and not session.has_key?(:previous_comtag)
      stored_location_for(resource_or_scope) || super  
    elsif true
      # Send everybody to Order out of Chaos  
      logger.info("application#after_sign_in_path_for send everybody to order out of chaos")
      if session.has_key?(:previous_comtag) and session[:previous_comtag].to_s != ''
        session[:cur_baseurl] + "/dialogs/#{VOH_DISCUSSION_ID}/slider?comtag=#{session[:previous_comtag]}"        
      else
        session[:cur_baseurl] + "/dialogs/#{VOH_DISCUSSION_ID}/slider"
      end
    elsif dialog_id.to_i > 0
      logger.info("application#after_sign_in_path_for setting path to dialog slider list")
      session[:cur_baseurl] + "/dialogs/#{dialog_id}/slider"
    elsif group_id.to_i > 0
      logger.info("application#after_sign_in_path_for setting path to group forum")
      session[:cur_baseurl] + "/groups/#{group_id}/forum"      
    elsif current_participant.last_url.to_s != ''
      current_participant.last_url
    elsif session.has_key?(:previous_url) 
      logger.info("application#after_sign_in_path_for using previous_url from session")
      session[:previous_url]
    else  
      logger.info("application#after_sign_in_path_for using default path")
      super
    end  
    
  end
  
  def after_token_authentication
    #-- NB: This is unfortunately never run, as this is a model method and doesn't belong here.
    #-- This is called by automatic login, rather than after_sign_in_path_for
    logger.info("application#after_token_authentication")
    
    session[:cur_prefix] = ''
    session[:cur_baseurl] = ''
    session[:group_id] = 0
    session[:group_name] = ''
    session[:group_prefix] = ''
    session[:dialog_id] = 0
    session[:dialog_name] = ''
    session[:dialog_prefix] = ''
    
    #-- This will check if required fields have been entered, and remember it, so we will show only their profile if we're missing something.
    session[:has_required] = current_participant.has_required
    
    group_id,dialog_id = get_group_dialog_from_subdomain
    return if not group_id and not dialog_id
    group_id,dialog_id = check_group_and_dialog if session[:group_id].to_i == 0 and session[:dialog_id].to_i == 0

    if session[:dialog_prefix] != '' and session[:group_prefix] != ''
      session[:cur_prefix] = session[:dialog_prefix] + '.' + session[:group_prefix]
    elsif session[:group_prefix] != ''
      session[:cur_prefix] = session[:group_prefix]
    elsif session[:dialog_prefix] != ''
      session[:cur_prefix] = session[:dialog_prefix]
    end
    
    if session[:cur_prefix] != ''
      session[:cur_baseurl] = "https://" + session[:cur_prefix] + "." + ROOTDOMAIN    
    else
      session[:cur_baseurl] = "https://" + BASEDOMAIN    
    end
    logger.info("application#after_token_authentication cur_baseurl:#{session[:cur_baseurl]}")
    
    #if session[:cur_prefix] != '' and request.host != session[:cur_prefix] + "." + ROOTDOMAIN and BASEDOMAIN != 'intermix.dev'
    #  #-- If this is not the dev system, and if the subdomain isn't already right, redirect
    #  new_url = session[:cur_baseurl] . request.fullpath
    #  redirect_to new_url
    #end  
    
  end
  
  def redirect_if_not_voh
    #if Rails.env.production? and participant_signed_in? and not params.include?('auth_token')
    if Rails.env.production? and not params.include?('auth_token')
      xsub = ''
      for subdomain in request.subdomains
        if subdomain != 'intermix'
          xsub += '.' if xsub != ''
          xsub += subdomain
        end
      end
      if xsub != 'voh'
        new_url =  "https://voh.#{ROOTDOMAIN}#{request.fullpath}"
        redirect_to new_url
        return true
      end
    end    
    return false
  end

  def get_group_dialog_from_subdomain
    #-- If we've gotten a group and/or dialog shortname in the subdomain
    #-- Now, if anything other than voh. change it to that and reload
    @group_id = GLOBAL_GROUP_ID
    @dialog_id = VOH_DISCUSSION_ID
    session[:dialog_id] = @dialog_id
    session[:group_id] = @group_id     
    return @group_id, @dialog_id
    #------
    logger.info("application#get_group_dialog_from_subdomain: #{request.subdomains.join(' ')} signed_in: #{participant_signed_in? ? 'yes' : 'no'}")    
    xgroup_id = nil
    xdialog_id = nil
    for subdomain in request.subdomains
      subdomain = 'voh' if subdomain == 'ugc'
      @dialog = Dialog.find_by_shortname(subdomain)
      if @dialog
        xdialog_id = @dialog.id
        #if participant_signed_in?
          session[:dialog_id] = xdialog_id
          session[:dialog_name] = @dialog.name
          session[:dialog_prefix] = @dialog.shortname
          #env['warden'].session[:dialog_id] = @dialog_id
          #env['warden'].session[:dialog_name] = @dialog.name
        #end
      else
        if subdomain != 'intermix'
          @group = Group.find_by_shortname(subdomain)
          if @group
            xgroup_id = @group.id
            session[:group_id] = xgroup_id
            session[:group_name] = @group.name
            session[:group_prefix] = @group.shortname
            if participant_signed_in?
              @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).first
              @is_member = @group_participant ? true : false
              session[:group_is_member] = @is_member
              #env['warden'].session[:group_id] = @group_id
              #env['warden'].session[:group_name] = @group.name
            end
          else
            session[:group_id] = GLOBAL_GROUP_ID
            @group = Group.find_by_id(GLOBAL_GROUP_ID)
            session[:group_name] = @group.name
            session[:group_prefix] = @group.shortname
            if participant_signed_in?
              session[:group_is_member] = true
            end
          end
        end
      end
    end    
    if participant_signed_in? and ( xgroup_id != @group_id or xdialog_id != @dialog_id )
       current_participant.last_group_id = xgroup_id
       current_participant.last_dialog_id = xdialog_id
       current_participant.save
    end
    #@group_id = xgroup_id
    #@dialog_id = xdialog_id
    @group_id = "#{session[:group_id]}".to_i
    @dialog_id = "#{session[:dialog_id]}".to_i
    logger.info("application#get_group_dialog_from_subdomain group:#{session[:group_id]}/#{session[:group_prefix]} dialog:#{session[:dialog_id]}/#{session[:dialog_prefix]}")    
    if session[:dialog_prefix].to_s != '' and session[:group_prefix].to_s != ''
      session[:cur_prefix] = session[:dialog_prefix] + '.' + session[:group_prefix]
      session[:cur_baseurl] = "https://" + session[:cur_prefix] + "." + ROOTDOMAIN    
    end
    
    return @group_id, @dialog_id
  end  
  
  def check_group_and_dialog  
    #-- This is probably rather inconsistent. When do we call which method to look for group or dialog ids?
    #-- This is called from after_sign_in_path_for as a supplement to get_group_dialog_from_subdomain
    #-- It is also called before each action in the dialog controller
    #-- It is meant for people who're logged in, to make sure the group and discussion are set
    #-- We will set a cookie, to ensure that this gets run, but not more than once
    return if participant_signed_in? and session[:group_checked]
    logger.info("application#check_group_and_dialog")    
    was_missing = false
    if session[:group_id].to_i == 0
      was_missing = true
      get_group_dialog_from_subdomain
    end  
    if participant_signed_in? and session[:group_id].to_i == 0
      #-- Get our last group/dialog if we don't already have one
      session[:group_id] = current_participant.last_group_id.to_i
      session[:dialog_id] = current_participant.last_dialog_id if session[:dialog_id].to_i == 0
    end      
    if participant_signed_in? and session[:group_id].to_i == 0
      # If we don't have anything else, put them in the global town square
      session[:group_id] = GLOBAL_GROUP_ID
    end    
    if participant_signed_in? and (not session.has_key?(:group_is_member) or not session.has_key?(:group_prefix))
      #-- If  we don't know if the user is a member or the group prefix, look it up
      if session[:group_id].to_i > 0
        @group_id = session[:group_id]
        @group = Group.find_by_id(@group_id)
        if @group
          session[:group_name] = @group.name
          session[:group_prefix] = @group.shortname
          @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).first
          @is_member = @group_participant ? true : false
          session[:group_is_member] = @is_member
        else  
          session[:group_is_member] = false
          session[:group_prefix] = ''
        end
      else
        session[:group_is_member] = false          
        session[:group_prefix] = ''
      end
      if session[:dialog_id].to_i > 0
        @dialog_id = session[:dialog_id]
        @dialog = Dialog.find_by_id(@dialog_id)
        if @dialog
          session[:dialog_name] = @dialog.name
          session[:dialog_prefix] = @dialog.shortname
        end
      end      
    end
    if session[:dialog_prefix].to_s != '' and session[:group_prefix].to_s != ''
      session[:cur_prefix] = session[:dialog_prefix] + '.' + session[:group_prefix]
    elsif session[:group_prefix].to_s != ''
      session[:cur_prefix] = session[:group_prefix]
    elsif session[:dialog_prefix].to_s != ''
      session[:cur_prefix] = session[:dialog_prefix]
    end
    if session[:cur_prefix].to_s != ''
      session[:cur_baseurl] = "https://" + session[:cur_prefix] + "." + ROOTDOMAIN    
    else
      session[:cur_baseurl] = "https://" + BASEDOMAIN    
    end
    if was_missing and session[:group_id].to_i > 0
      #-- We set something
      logger.info("application#check_group_and_dialog setting last group/dialog group:#{session[:group_id]}/#{session[:group_prefix]} dialog:#{session[:dialog_id]}/#{session[:dialog_prefix]}")    
    end
    session[:group_checked] = true if participant_signed_in?    
    return session[:group_id], session[:dialog_id]
  end
  
  
  def check_required
    #-- If required profile fields aren't entered, redirect to the profile
    if not participant_signed_in?
      return
    elsif not session[:has_required]
      session[:has_required] = current_participant.has_required
      if not session[:has_required]
        redirect_to :controller => :profiles, :action=>:edit
      end
    end
  end
  
  def check_status
    #-- Check the status of the logged-in user
    if not participant_signed_in?
      return
    elsif current_participant.status == 'unconfirmed'
      sign_out :participant 
      flash[:alert] = "Your account is not yet active.<br>Please confirm your account by clicking on the link in the e-mail we sent you."
      redirect_to '/'
    elsif current_participant.status != 'active'
      sign_out :participant 
      flash[:alert] = "Your account is not active"
      redirect_to '/'
    end     
  end
  
  def is_sysadmin
    if not participant_signed_in?
      redirect_to '/'
      return false
    elsif current_participant.sysadmin
      return true
    else
      redirect_to '/'
      return false
    end      
  end 
  
  def current_user
    if participant_signed_in?
      current_participant 
    else
      nil
    end  
  end   
  
  #-- To replace devise's token authorization. https://gist.github.com/josevalim/fb706b1e933ef01e4fb6
  # For this example, we are simply using token authentication
  # via parameters. However, anyone could use Rails's token
  # authentication features to get the token from a header.
  def authenticate_user_from_token!
    auth_token = params[:auth_token].presence
    participant       = auth_token && Participant.find_by_authentication_token(auth_token.to_s)

    if participant
      # Notice we are passing store false, so the user is not
      # actually stored in the session and a token is needed
      # for every request. If you want the token to work as a
      # sign in token, you can simply remove store: false.
      sign_in participant
    end
  end
  
  def julian(year, month, day)
    a = (14-month)/12
    y = year+4800-a
    m = (12*a)-3+month
    return day + (153*m+2)/5 + (365*y) + y/4 - y/100 + y/400 - 32045
  end
  
  def moonphase(year,month,day)
    p=(julian(year,month,day)-julian(2000,1,6))%29.530588853
    if p<1.84566
      return "New"
    elsif p<5.53699
      return "Waxing crescent"
    elsif p<9.22831
      return "First quarter"
    elsif p<12.91963
      return "Waxing gibbous"
    elsif p<16.61096
      return "Full"
    elsif p<20.30228
      return "Waning gibbous"
    elsif p<23.99361
      return "Last quarter"
    elsif p<27.68493
      return "Waning crescent"
    else
      return "New"
    end
  end
  
  #print "#{phase(2020,1,23)}\n"
  #print "#{phase(1999,1,6)}\n"
  #print "#{phase(2010,2,10)}\n"
  #print "#{phase(1987,5,10)}\n"


  private
  
    def storable_location?
      # Its important that the location is NOT stored if:
      # - The request method is not GET (non idempotent)
      # - The request is handled by a Devise controller such as Devise::SessionsController as that could cause an 
      #    infinite redirect loop.
      # - The request is an Ajax request as this can lead to very unexpected behaviour.
      request.get? && is_navigational_format? && !devise_controller? && !request.xhr? 
    end

    def store_user_location!
      # :user is the scope we are authenticating
      store_location_for(:user, request.fullpath)
    end
        
end
