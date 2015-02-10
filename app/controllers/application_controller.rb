# encoding: utf-8

class ApplicationController < ActionController::Base
  protect_from_forgery  

	layout "front"

  helper_method :sanitizethis, :get_group_dialog_from_subdomain

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
    render :layout=>false, :text => "ok"
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
  
  def get_embedly(url)
    #-- Look up a media link in embed.ly and return the fields:
    # type (required) The resource type. Valid values, along with value-specific parameters, are described below.
    # version (required) The oEmbed version number. This must be 1.0.
    # title (optional) A text title, describing the resource.
    # author_name (optional) The name of the author/owner of the resource.
    # author_url (optional) A URL for the author/owner of the resource.
    # provider_name (optional) The name of the resource provider.
    # provider_url (optional) The url of the resource provider.
    # cache_age (optional) The suggested cache lifetime for this resource, in seconds. Consumers may choose to use this value or not.
    # thumbnail_url (optional) A URL to a thumbnail image representing the resource. The thumbnail must respect any maxwidth and maxheight parameters. If this parameter is present , thumbnail_width and thumbnail_height must also be present.
    # thumbnail_width (optional) The width of the optional thumbnail. If this parameter is present, thumbnail_url and thumbnail_height must also be present.
    # thumbnail_height (optional) The height of the optional thumbnail. If this parameter is present, thumbnail_url and thumbnail_width must also be present.
    # description We support and pass back a description for all oEmbed types.
    # see: http://api.embed.ly/docs/oembed
    return {} if not url or url.to_s == ''
    
    #-- Check if it is a supported service
    #-- This regular expression should be updated once in a while from http://api.embed.ly/tools/generator
    embedly_re = Regexp.new(/http:\/\/(.*youtube\.com\/watch.*|.*\.youtube\.com\/v\/.*|youtu\.be\/.*|.*\.youtube\.com\/user\/.*|.*\.youtube\.com\/.*#.*\/.*|m\.youtube\.com\/watch.*|m\.youtube\.com\/index.*|.*\.youtube\.com\/profile.*|.*justin\.tv\/.*|.*justin\.tv\/.*\/b\/.*|.*justin\.tv\/.*\/w\/.*|www\.ustream\.tv\/recorded\/.*|www\.ustream\.tv\/channel\/.*|www\.ustream\.tv\/.*|qik\.com\/video\/.*|qik\.com\/.*|qik\.ly\/.*|.*revision3\.com\/.*|.*\.dailymotion\.com\/video\/.*|.*\.dailymotion\.com\/.*\/video\/.*|www\.collegehumor\.com\/video:.*|.*twitvid\.com\/.*|www\.break\.com\/.*\/.*|vids\.myspace\.com\/index\.cfm\?fuseaction=vids\.individual&videoid.*|www\.myspace\.com\/index\.cfm\?fuseaction=.*&videoid.*|www\.metacafe\.com\/watch\/.*|www\.metacafe\.com\/w\/.*|blip\.tv\/file\/.*|.*\.blip\.tv\/file\/.*|video\.google\.com\/videoplay\?.*|.*revver\.com\/video\/.*|video\.yahoo\.com\/watch\/.*\/.*|video\.yahoo\.com\/network\/.*|.*viddler\.com\/explore\/.*\/videos\/.*|liveleak\.com\/view\?.*|www\.liveleak\.com\/view\?.*|animoto\.com\/play\/.*|dotsub\.com\/view\/.*|www\.overstream\.net\/view\.php\?oid=.*|www\.livestream\.com\/.*|www\.worldstarhiphop\.com\/videos\/video.*\.php\?v=.*|worldstarhiphop\.com\/videos\/video.*\.php\?v=.*|teachertube\.com\/viewVideo\.php.*|www\.teachertube\.com\/viewVideo\.php.*|www1\.teachertube\.com\/viewVideo\.php.*|www2\.teachertube\.com\/viewVideo\.php.*|bambuser\.com\/v\/.*|bambuser\.com\/channel\/.*|bambuser\.com\/channel\/.*\/broadcast\/.*|www\.schooltube\.com\/video\/.*\/.*|bigthink\.com\/ideas\/.*|bigthink\.com\/series\/.*|sendables\.jibjab\.com\/view\/.*|sendables\.jibjab\.com\/originals\/.*|www\.xtranormal\.com\/watch\/.*|dipdive\.com\/media\/.*|dipdive\.com\/member\/.*\/media\/.*|dipdive\.com\/v\/.*|.*\.dipdive\.com\/media\/.*|.*\.dipdive\.com\/v\/.*|v\.youku\.com\/v_show\/.*\.html|v\.youku\.com\/v_playlist\/.*\.html|.*yfrog\..*\/.*|tweetphoto\.com\/.*|www\.flickr\.com\/photos\/.*|flic\.kr\/.*|twitpic\.com\/.*|www\.twitpic\.com\/.*|twitpic\.com\/photos\/.*|www\.twitpic\.com\/photos\/.*|.*imgur\.com\/.*|.*\.posterous\.com\/.*|post\.ly\/.*|twitgoo\.com\/.*|i.*\.photobucket\.com\/albums\/.*|s.*\.photobucket\.com\/albums\/.*|phodroid\.com\/.*\/.*\/.*|www\.mobypicture\.com\/user\/.*\/view\/.*|moby\.to\/.*|xkcd\.com\/.*|www\.xkcd\.com\/.*|imgs\.xkcd\.com\/.*|www\.asofterworld\.com\/index\.php\?id=.*|www\.asofterworld\.com\/.*\.jpg|asofterworld\.com\/.*\.jpg|www\.qwantz\.com\/index\.php\?comic=.*|23hq\.com\/.*\/photo\/.*|www\.23hq\.com\/.*\/photo\/.*|.*dribbble\.com\/shots\/.*|drbl\.in\/.*|.*\.smugmug\.com\/.*|.*\.smugmug\.com\/.*#.*|emberapp\.com\/.*\/images\/.*|emberapp\.com\/.*\/images\/.*\/sizes\/.*|emberapp\.com\/.*\/collections\/.*\/.*|emberapp\.com\/.*\/categories\/.*\/.*\/.*|embr\.it\/.*|picasaweb\.google\.com.*\/.*\/.*#.*|picasaweb\.google\.com.*\/lh\/photo\/.*|picasaweb\.google\.com.*\/.*\/.*|dailybooth\.com\/.*\/.*|brizzly\.com\/pic\/.*|pics\.brizzly\.com\/.*\.jpg|img\.ly\/.*|www\.tinypic\.com\/view\.php.*|tinypic\.com\/view\.php.*|www\.tinypic\.com\/player\.php.*|tinypic\.com\/player\.php.*|www\.tinypic\.com\/r\/.*\/.*|tinypic\.com\/r\/.*\/.*|.*\.tinypic\.com\/.*\.jpg|.*\.tinypic\.com\/.*\.png|meadd\.com\/.*\/.*|meadd\.com\/.*|.*\.deviantart\.com\/art\/.*|.*\.deviantart\.com\/gallery\/.*|.*\.deviantart\.com\/#\/.*|fav\.me\/.*|.*\.deviantart\.com|.*\.deviantart\.com\/gallery|.*\.deviantart\.com\/.*\/.*\.jpg|.*\.deviantart\.com\/.*\/.*\.gif|.*\.deviantart\.net\/.*\/.*\.jpg|.*\.deviantart\.net\/.*\/.*\.gif|plixi\.com\/p\/.*|plixi\.com\/profile\/home\/.*|plixi\.com\/.*|www\.fotopedia\.com\/.*\/.*|fotopedia\.com\/.*\/.*|photozou\.jp\/photo\/show\/.*\/.*|photozou\.jp\/photo\/photo_only\/.*\/.*|instagr\.am\/p\/.*|skitch\.com\/.*\/.*\/.*|img\.skitch\.com\/.*|https:\/\/skitch\.com\/.*\/.*\/.*|https:\/\/img\.skitch\.com\/.*|share\.ovi\.com\/media\/.*\/.*|www\.questionablecontent\.net\/|questionablecontent\.net\/|www\.questionablecontent\.net\/view\.php.*|questionablecontent\.net\/view\.php.*|questionablecontent\.net\/comics\/.*\.png|www\.questionablecontent\.net\/comics\/.*\.png|picplz\.com\/user\/.*\/pic\/.*\/|twitrpix\.com\/.*|.*\.twitrpix\.com\/.*|www\.someecards\.com\/.*\/.*|someecards\.com\/.*\/.*|some\.ly\/.*|www\.some\.ly\/.*|pikchur\.com\/.*|achewood\.com\/.*|www\.achewood\.com\/.*|achewood\.com\/index\.php.*|www\.achewood\.com\/index\.php.*|www\.whitehouse\.gov\/photos-and-video\/video\/.*|www\.whitehouse\.gov\/video\/.*|wh\.gov\/photos-and-video\/video\/.*|wh\.gov\/video\/.*|www\.hulu\.com\/watch.*|www\.hulu\.com\/w\/.*|hulu\.com\/watch.*|hulu\.com\/w\/.*|.*crackle\.com\/c\/.*|www\.fancast\.com\/.*\/videos|www\.funnyordie\.com\/videos\/.*|www\.funnyordie\.com\/m\/.*|funnyordie\.com\/videos\/.*|funnyordie\.com\/m\/.*|www\.vimeo\.com\/groups\/.*\/videos\/.*|www\.vimeo\.com\/.*|vimeo\.com\/m\/#\/featured\/.*|vimeo\.com\/groups\/.*\/videos\/.*|vimeo\.com\/.*|vimeo\.com\/m\/#\/featured\/.*|www\.ted\.com\/talks\/.*\.html.*|www\.ted\.com\/talks\/lang\/.*\/.*\.html.*|www\.ted\.com\/index\.php\/talks\/.*\.html.*|www\.ted\.com\/index\.php\/talks\/lang\/.*\/.*\.html.*|.*nfb\.ca\/film\/.*|www\.thedailyshow\.com\/watch\/.*|www\.thedailyshow\.com\/full-episodes\/.*|www\.thedailyshow\.com\/collection\/.*\/.*\/.*|movies\.yahoo\.com\/movie\/.*\/video\/.*|movies\.yahoo\.com\/movie\/.*\/trailer|movies\.yahoo\.com\/movie\/.*\/video|www\.colbertnation\.com\/the-colbert-report-collections\/.*|www\.colbertnation\.com\/full-episodes\/.*|www\.colbertnation\.com\/the-colbert-report-videos\/.*|www\.comedycentral\.com\/videos\/index\.jhtml\?.*|www\.theonion\.com\/video\/.*|theonion\.com\/video\/.*|wordpress\.tv\/.*\/.*\/.*\/.*\/|www\.traileraddict\.com\/trailer\/.*|www\.traileraddict\.com\/clip\/.*|www\.traileraddict\.com\/poster\/.*|www\.escapistmagazine\.com\/videos\/.*|www\.trailerspy\.com\/trailer\/.*\/.*|www\.trailerspy\.com\/trailer\/.*|www\.trailerspy\.com\/view_video\.php.*|www\.atom\.com\/.*\/.*\/|fora\.tv\/.*\/.*\/.*\/.*|www\.spike\.com\/video\/.*|www\.gametrailers\.com\/video\/.*|gametrailers\.com\/video\/.*|www\.koldcast\.tv\/video\/.*|www\.koldcast\.tv\/#video:.*|techcrunch\.tv\/watch.*|techcrunch\.tv\/.*\/watch.*|mixergy\.com\/.*|video\.pbs\.org\/video\/.*|www\.zapiks\.com\/.*|tv\.digg\.com\/diggnation\/.*|tv\.digg\.com\/diggreel\/.*|tv\.digg\.com\/diggdialogg\/.*|www\.trutv\.com\/video\/.*|www\.nzonscreen\.com\/title\/.*|nzonscreen\.com\/title\/.*|app\.wistia\.com\/embed\/medias\/.*|https:\/\/app\.wistia\.com\/embed\/medias\/.*|hungrynation\.tv\/.*\/episode\/.*|www\.hungrynation\.tv\/.*\/episode\/.*|hungrynation\.tv\/episode\/.*|www\.hungrynation\.tv\/episode\/.*|indymogul\.com\/.*\/episode\/.*|www\.indymogul\.com\/.*\/episode\/.*|indymogul\.com\/episode\/.*|www\.indymogul\.com\/episode\/.*|channelfrederator\.com\/.*\/episode\/.*|www\.channelfrederator\.com\/.*\/episode\/.*|channelfrederator\.com\/episode\/.*|www\.channelfrederator\.com\/episode\/.*|tmiweekly\.com\/.*\/episode\/.*|www\.tmiweekly\.com\/.*\/episode\/.*|tmiweekly\.com\/episode\/.*|www\.tmiweekly\.com\/episode\/.*|99dollarmusicvideos\.com\/.*\/episode\/.*|www\.99dollarmusicvideos\.com\/.*\/episode\/.*|99dollarmusicvideos\.com\/episode\/.*|www\.99dollarmusicvideos\.com\/episode\/.*|ultrakawaii\.com\/.*\/episode\/.*|www\.ultrakawaii\.com\/.*\/episode\/.*|ultrakawaii\.com\/episode\/.*|www\.ultrakawaii\.com\/episode\/.*|barelypolitical\.com\/.*\/episode\/.*|www\.barelypolitical\.com\/.*\/episode\/.*|barelypolitical\.com\/episode\/.*|www\.barelypolitical\.com\/episode\/.*|barelydigital\.com\/.*\/episode\/.*|www\.barelydigital\.com\/.*\/episode\/.*|barelydigital\.com\/episode\/.*|www\.barelydigital\.com\/episode\/.*|threadbanger\.com\/.*\/episode\/.*|www\.threadbanger\.com\/.*\/episode\/.*|threadbanger\.com\/episode\/.*|www\.threadbanger\.com\/episode\/.*|vodcars\.com\/.*\/episode\/.*|www\.vodcars\.com\/.*\/episode\/.*|vodcars\.com\/episode\/.*|www\.vodcars\.com\/episode\/.*|confreaks\.net\/videos\/.*|www\.confreaks\.net\/videos\/.*|www\.godtube\.com\/featured\/video\/.*|godtube\.com\/featured\/video\/.*|www\.godtube\.com\/watch\/.*|godtube\.com\/watch\/.*|www\.tangle\.com\/view_video.*|mediamatters\.org\/mmtv\/.*|www\.clikthrough\.com\/theater\/video\/.*|soundcloud\.com\/.*|soundcloud\.com\/.*\/.*|soundcloud\.com\/.*\/sets\/.*|soundcloud\.com\/groups\/.*|snd\.sc\/.*|www\.last\.fm\/music\/.*|www\.last\.fm\/music\/+videos\/.*|www\.last\.fm\/music\/+images\/.*|www\.last\.fm\/music\/.*\/_\/.*|www\.last\.fm\/music\/.*\/.*|www\.mixcloud\.com\/.*\/.*\/|www\.radionomy\.com\/.*\/radio\/.*|radionomy\.com\/.*\/radio\/.*|www\.entertonement\.com\/clips\/.*|www\.rdio\.com\/#\/artist\/.*\/album\/.*|www\.rdio\.com\/artist\/.*\/album\/.*|www\.zero-inch\.com\/.*|.*\.bandcamp\.com\/|.*\.bandcamp\.com\/track\/.*|.*\.bandcamp\.com\/album\/.*|freemusicarchive\.org\/music\/.*|www\.freemusicarchive\.org\/music\/.*|freemusicarchive\.org\/curator\/.*|www\.freemusicarchive\.org\/curator\/.*|www\.npr\.org\/.*\/.*\/.*\/.*\/.*|www\.npr\.org\/.*\/.*\/.*\/.*\/.*\/.*|www\.npr\.org\/.*\/.*\/.*\/.*\/.*\/.*\/.*|www\.npr\.org\/templates\/story\/story\.php.*|huffduffer\.com\/.*\/.*|www\.audioboo\.fm\/boos\/.*|audioboo\.fm\/boos\/.*|boo\.fm\/b.*|www\.xiami\.com\/song\/.*|xiami\.com\/song\/.*|espn\.go\.com\/video\/clip.*|espn\.go\.com\/.*\/story.*|abcnews\.com\/.*\/video\/.*|abcnews\.com\/video\/playerIndex.*|washingtonpost\.com\/wp-dyn\/.*\/video\/.*\/.*\/.*\/.*|www\.washingtonpost\.com\/wp-dyn\/.*\/video\/.*\/.*\/.*\/.*|www\.boston\.com\/video.*|boston\.com\/video.*|www\.facebook\.com\/photo\.php.*|www\.facebook\.com\/video\/video\.php.*|www\.facebook\.com\/v\/.*|cnbc\.com\/id\/.*\?.*video.*|www\.cnbc\.com\/id\/.*\?.*video.*|cnbc\.com\/id\/.*\/play\/1\/video\/.*|www\.cnbc\.com\/id\/.*\/play\/1\/video\/.*|cbsnews\.com\/video\/watch\/.*|www\.google\.com\/buzz\/.*\/.*\/.*|www\.google\.com\/buzz\/.*|www\.google\.com\/profiles\/.*|google\.com\/buzz\/.*\/.*\/.*|google\.com\/buzz\/.*|google\.com\/profiles\/.*|www\.cnn\.com\/video\/.*|edition\.cnn\.com\/video\/.*|money\.cnn\.com\/video\/.*|today\.msnbc\.msn\.com\/id\/.*\/vp\/.*|www\.msnbc\.msn\.com\/id\/.*\/vp\/.*|www\.msnbc\.msn\.com\/id\/.*\/ns\/.*|today\.msnbc\.msn\.com\/id\/.*\/ns\/.*|multimedia\.foxsports\.com\/m\/video\/.*\/.*|msn\.foxsports\.com\/video.*|www\.globalpost\.com\/video\/.*|www\.globalpost\.com\/dispatch\/.*|.*amazon\..*\/gp\/product\/.*|.*amazon\..*\/.*\/dp\/.*|.*amazon\..*\/dp\/.*|.*amazon\..*\/o\/ASIN\/.*|.*amazon\..*\/gp\/offer-listing\/.*|.*amazon\..*\/.*\/ASIN\/.*|.*amazon\..*\/gp\/product\/images\/.*|www\.amzn\.com\/.*|amzn\.com\/.*|www\.shopstyle\.com\/browse.*|www\.shopstyle\.com\/action\/apiVisitRetailer.*|api\.shopstyle\.com\/action\/apiVisitRetailer.*|www\.shopstyle\.com\/action\/viewLook.*|gist\.github\.com\/.*|twitter\.com\/.*\/status\/.*|twitter\.com\/.*\/statuses\/.*|mobile\.twitter\.com\/.*\/status\/.*|mobile\.twitter\.com\/.*\/statuses\/.*|www\.crunchbase\.com\/.*\/.*|crunchbase\.com\/.*\/.*|www\.slideshare\.net\/.*\/.*|www\.slideshare\.net\/mobile\/.*\/.*|.*\.scribd\.com\/doc\/.*|screenr\.com\/.*|polldaddy\.com\/community\/poll\/.*|polldaddy\.com\/poll\/.*|answers\.polldaddy\.com\/poll\/.*|www\.5min\.com\/Video\/.*|www\.howcast\.com\/videos\/.*|www\.screencast\.com\/.*\/media\/.*|screencast\.com\/.*\/media\/.*|www\.screencast\.com\/t\/.*|screencast\.com\/t\/.*|issuu\.com\/.*\/docs\/.*|www\.kickstarter\.com\/projects\/.*\/.*|www\.scrapblog\.com\/viewer\/viewer\.aspx.*|ping\.fm\/p\/.*|chart\.ly\/symbols\/.*|chart\.ly\/.*|maps\.google\.com\/maps\?.*|maps\.google\.com\/\?.*|maps\.google\.com\/maps\/ms\?.*|.*\.craigslist\.org\/.*\/.*|my\.opera\.com\/.*\/albums\/show\.dml\?id=.*|my\.opera\.com\/.*\/albums\/showpic\.dml\?album=.*&picture=.*|tumblr\.com\/.*|.*\.tumblr\.com\/post\/.*|www\.polleverywhere\.com\/polls\/.*|www\.polleverywhere\.com\/multiple_choice_polls\/.*|www\.polleverywhere\.com\/free_text_polls\/.*|www\.quantcast\.com\/wd:.*|www\.quantcast\.com\/.*|siteanalytics\.compete\.com\/.*|statsheet\.com\/statplot\/charts\/.*\/.*\/.*\/.*|statsheet\.com\/statplot\/charts\/e\/.*|statsheet\.com\/.*\/teams\/.*\/.*|statsheet\.com\/tools\/chartlets\?chart=.*|.*\.status\.net\/notice\/.*|identi\.ca\/notice\/.*|brainbird\.net\/notice\/.*|shitmydadsays\.com\/notice\/.*|www\.studivz\.net\/Profile\/.*|www\.studivz\.net\/l\/.*|www\.studivz\.net\/Groups\/Overview\/.*|www\.studivz\.net\/Gadgets\/Info\/.*|www\.studivz\.net\/Gadgets\/Install\/.*|www\.studivz\.net\/.*|www\.meinvz\.net\/Profile\/.*|www\.meinvz\.net\/l\/.*|www\.meinvz\.net\/Groups\/Overview\/.*|www\.meinvz\.net\/Gadgets\/Info\/.*|www\.meinvz\.net\/Gadgets\/Install\/.*|www\.meinvz\.net\/.*|www\.schuelervz\.net\/Profile\/.*|www\.schuelervz\.net\/l\/.*|www\.schuelervz\.net\/Groups\/Overview\/.*|www\.schuelervz\.net\/Gadgets\/Info\/.*|www\.schuelervz\.net\/Gadgets\/Install\/.*|www\.schuelervz\.net\/.*|myloc\.me\/.*|pastebin\.com\/.*|pastie\.org\/.*|www\.pastie\.org\/.*|redux\.com\/stream\/item\/.*\/.*|redux\.com\/f\/.*\/.*|www\.redux\.com\/stream\/item\/.*\/.*|www\.redux\.com\/f\/.*\/.*|cl\.ly\/.*|cl\.ly\/.*\/content|speakerdeck\.com\/u\/.*\/p\/.*|www\.kiva\.org\/lend\/.*|www\.timetoast\.com\/timelines\/.*|storify\.com\/.*\/.*|.*meetup\.com\/.*|meetu\.ps\/.*|www\.dailymile\.com\/people\/.*\/entries\/.*|.*\.kinomap\.com\/.*|www\.metacdn\.com\/api\/users\/.*\/content\/.*|www\.metacdn\.com\/api\/users\/.*\/media\/.*|prezi\.com\/.*\/.*|.*\.uservoice\.com\/.*\/suggestions\/.*|formspring\.me\/.*|www\.formspring\.me\/.*|formspring\.me\/.*\/q\/.*|www\.formspring\.me\/.*\/q\/.*|twitlonger\.com\/show\/.*|www\.twitlonger\.com\/show\/.*|tl\.gd\/.*)/i)
        
    my_provider = OEmbed::Provider.new("http://api.embed.ly/1/oembed")
    begin
      resource = my_provider.get(url)
      resource.fields
    rescue
      {}
    end    
  end
  
  def sanitizethis(sometext)
    Sanitize.clean(sometext.force_encoding("UTF-8"), 
      :elements => ['a', 'p', 'br', 'u', 'b', 'em', 'strong', 'ul', 'li', 'h1', 'h2', 'h3','table','tr','tbody','td','img'],
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
    group_id,dialog_id = check_group_and_dialog if session[:group_id].to_i == 0 and session[:dialog_id].to_i == 0

    if session[:dialog_prefix] != '' and session[:group_prefix] != ''
      session[:cur_prefix] = session[:dialog_prefix] + '.' + session[:group_prefix]
    elsif session[:group_prefix] != ''
      session[:cur_prefix] = session[:group_prefix]
    elsif session[:dialog_prefix] != ''
      session[:cur_prefix] = session[:dialog_prefix]
    end
    
    if session[:cur_prefix] != ''
      session[:cur_baseurl] = "http://" + session[:cur_prefix] + "." + ROOTDOMAIN    
    else
      session[:cur_baseurl] = "http://" + BASEDOMAIN    
    end
    logger.info("application#after_sign_in_path_for cur_baseurl:#{session[:cur_baseurl]}")

    #-- See if they're a moderator of a group, or a hub admin. Only those can add new discussions.
    groupsmodof = GroupParticipant.where("participant_id=#{current_participant.id} and moderator=1")
    session[:is_group_moderator] = (groupsmodof.length > 0)
    hubadmins = HubAdmin.where("participant_id=#{current_participant.id} and active=1")
    session[:is_hub_admin] = (hubadmins.length > 0)
    session[:is_sysadmin] = current_participant.sysadmin
    session[:is_anyadmin] = (session[:is_group_moderator] or session[:is_hub_admin] or session[:is_sysadmin])
  
    if dialog_id.to_i>0 and group_id.to_i > 0
      @group = Group.find_by_id(group_id) if not @group
      #-- Check if they're a member of the group. If not, join them
      if @group.openness == 'open'
        group_participant = GroupParticipant.where("participant_id=#{current_participant.id} and group_id=#{group_id}").first
        if not group_participant
          group_participant = GroupParticipant.new(:group_id=>group_id,:participant_id=>current_participant.id)
          group_participant.active = true
          group_participant.status = 'active'
          group_participant.save
          session[:group_is_member] = true
        end
      end
    end  
    
    if current_participant.fb_uid.to_i >0 and not current_participant.picture.exists?
      #-- If they don't have a picture set, and they have a facebook account, get it from there
      url = "https://graph.facebook.com/#{current_participant.fb_uid}/picture?type=large"
      current_participant.picture = URI.parse(url)
      current_participant.save!
    end
  
    if params[:fb_sig_in_iframe].to_i == 1
      session[:cur_baseurl] + '/fbapp'
    elsif not session[:has_required]
      #session[:cur_baseurl] + '/me/profile/edit#settings'
      session[:cur_baseurl] + '/me/profile/meta'
    elsif dialog_id.to_i > 0
      logger.info("application#after_sign_in_path_for setting path to dialog forum")
      session[:cur_baseurl] + "/dialogs/#{dialog_id}/forum"
    elsif group_id.to_i > 0
      logger.info("application#after_sign_in_path_for setting path to group forum")
      session[:cur_baseurl] + "/groups/#{group_id}/forum"      
    elsif current_participant.last_url.to_s != ''
      current_participant.last_url
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
    group_id,dialog_id = check_group_and_dialog if session[:group_id].to_i == 0 and session[:dialog_id].to_i == 0

    if session[:dialog_prefix] != '' and session[:group_prefix] != ''
      session[:cur_prefix] = session[:dialog_prefix] + '.' + session[:group_prefix]
    elsif session[:group_prefix] != ''
      session[:cur_prefix] = session[:group_prefix]
    elsif session[:dialog_prefix] != ''
      session[:cur_prefix] = session[:dialog_prefix]
    end
    
    if session[:cur_prefix] != ''
      session[:cur_baseurl] = "http://" + session[:cur_prefix] + "." + ROOTDOMAIN    
    else
      session[:cur_baseurl] = "http://" + BASEDOMAIN    
    end
    logger.info("application#after_token_authentication cur_baseurl:#{session[:cur_baseurl]}")
    
    if session[:cur_prefix] != '' and request.host != session[:cur_prefix] + "." + ROOTDOMAIN and BASEDOMAIN != 'intermix.dev'
      #-- If this is not the dev system, and if the subdomain isn't already right, redirect
      new_url = session[:cur_baseurl] . request.fullpath
      redirect_to new_url
    end  
    
  end

  def get_group_dialog_from_subdomain
    #-- If we've gotten a group and/or dialog shortname in the subdomain
    logger.info("application#get_group_dialog_from_subdomain: #{request.subdomains.join(' ')} signed_in: #{participant_signed_in? ? 'yes' : 'no'}")    
    xgroup_id = nil
    xdialog_id = nil
    for subdomain in request.subdomains
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
    return @group_id, @dialog_id
  end  
  
  def check_group_and_dialog  
    #-- This is probably rather inconsistent. When do we call which method to look for group or dialog ids?
    #-- This is called from after_sign_in_path_for as a supplement to get_group_dialog_from_subdomain
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
      session[:group_id] = current_participant.last_group_id
      session[:dialog_id] = current_participant.last_dialog_id if session[:dialog_id].to_i == 0
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
      session[:cur_baseurl] = "http://" + session[:cur_prefix] + "." + ROOTDOMAIN    
    else
      session[:cur_baseurl] = "http://" + BASEDOMAIN    
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
    if not session[:has_required]
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
        
end
