class ProfilesController < ApplicationController
  
  layout "front"
  before_filter :authenticate_participant!, :check_group_and_dialog
  
  def index
    @section = 'profile'
    profile
    update_last_url
  end  
  
  def profile
    #-- show your own profile
    @section = 'profile'
    @subsection = 'view'
    @participant_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.includes(:metro_area).find(@participant_id)
    render :action=>:index
    update_last_url
  end  
  
  def edit
    @section = 'profile'
    @subsection = 'edit'
    @profile_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.find_by_id(@profile_id)
    @participant.new_signup = false
    @participant.save
    session[:has_required] = @participant.has_required
    if @participant.country_code.to_s != ''
      @metro_areas = MetroArea.where(:country_code=>@participant.country_code).order(:name).all.collect{|r| [r.name,r.id]}
    else  
      @metro_areas = MetroArea.includes(:geocountry).order("geocountries.name,metro_areas.name").all.collect{|r| ["#{r.geocountry.name}: #{r.name}",r.id]}
    end
    flash.now[:alert] = "Some required fields need to be entered" if not session[:has_required]
    @group = Group.find_by_id(session[:group_id]) if not @group and session[:group_id].to_i > 0
    if session[:dialog_id].to_i > 0
      @forum_link = "/dialogs/#{session[:dialog_id]}/forum"
    elsif @group
      @forum_link = "/groups/#{@group.id}/forum"
    else
      @forum_link = ''
    end  
  end

  def settings
    @section = 'profile'
    @subsection = 'settings'
    @profile_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.find(@profile_id)
    if @participant.direct_email_code.to_s == ''
      trycode = Digest::MD5.hexdigest(Time.now.to_f.to_s)[6,10]
      matches = Participant.where("direct_email_code='#{trycode}'").all
      if matches and matches.length > 0
        logger.info("profiles#settings duplicate direct_email_code:#{trycode}")
      else
        @participant.direct_email_code = trycode
        @participant.save
      end
    end  
    update_last_url
  end
  
  def update
    @section = 'profile'
    @subsection = params[:subsection].to_s
    @profile_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.find(@profile_id)
    logger.info("profiles#update #{@participant.id}")
    @goto = params[:goto]  # Maybe a (forum) link to continue to after saving
        
    geoupdate
    @participant.has_participated = true
    
    flash.now[:alert] = ''
    flash.now[:notice] = ''

    old_pass = params[:old_pass].to_s
    new_pass = params[:new_pass].to_s
    new_pass_confirm = params[:new_pass_confirm].to_s
    if new_pass != ''
      if old_pass == ''
        flash.now[:alert] += "Please enter your old password if you want to change it."
      elsif not current_participant.valid_password?(old_pass)
        flash.now[:alert] += "That doesn't seem to be the right password."
      elsif new_pass_confirm == ''
        flash.now[:alert] += "Please enter the new password a second time if you want to change it."
      elsif new_pass_confirm != new_pass
        flash.now[:alert] += "The two passwords don't match."
      else  
        @participant.password = new_pass
        @participant.save
        flash.now[:notice] = "Password changed."
      end
    end
    
    @participant.assign_attributes(params[:participant])

    flash.now[:alert] += 'First name is required<br>' if params[:participant].has_key?(:first_name) and @participant.first_name.to_s == ''
    flash.now[:alert] += 'Last name is required<br>' if params[:participant].has_key?(:last_name) and @participant.last_name.to_s == ''
    flash.now[:alert] += 'Country is required<br>' if params[:participant].has_key?(:country_code) and @participant.country_code.to_s == ''
    flash.now[:alert] += 'Visibility is required<br>' if params[:participant].has_key?(:visibility) and @participant.visibility.to_s == ''
    flash.now[:alert] += 'Personal message e-mail preference is required<br>' if params[:participant].has_key?(:private_email) and @participant.private_email.to_s == ''
    flash.now[:alert] += 'System message e-mail preference is required<br>' if params[:participant].has_key?(:system_email) and @participant.system_email.to_s == ''
    flash.now[:alert] += 'Forum posting e-mail preference is required<br>' if params[:participant].has_key?(:forum_email) and @participant.forum_email.to_s == ''

    # Save any metamap assignments
    if params[:meta]
      @participant.metamaps_h.each do |metamap_id,metamap_name|
        val = params[:meta]["#{metamap_id}"].to_i
        if val > 0
          mnp = MetamapNodeParticipant.where(:metamap_id=>metamap_id,:participant_id=>@participant.id).first
          if mnp
            mnp.metamap_node_id = val
            mnp.save
          else
            MetamapNodeParticipant.create(:metamap_id=>metamap_id,:metamap_node_id=>val,:participant_id=>@participant.id)
          end  
        elsif metamap_id==3 or metamap_id==5   
           flash.now[:alert] += "#{metamap_name} is required by InterMix<br>"
        else
          flash.now[:alert] += "#{metamap_name} is required by one of the groups or discussions you're in<br>"             
        end
      end 
    end    

    if flash.now[:alert] != ""
      @subsection = 'edit'
      render :action => "edit"
      return
    end
    
    if @participant.save
      
      if @participant.twitter_username == '' and @participant.twitter_oauth_token != ''
        @participant.twitter_oauth_token = ''
        @participant.twitter_oauth_secret = ''
        @participant.save
      end  
      
      @alert = ""
      if @subsection == 'settings'
        @notice = "OK New Settings have been saved."
      else
        @notice = "Profile has been updated."
      end
      
      #-- Update the setting for whether required fields were entered or not
      session[:has_required] = @participant.has_required
      
      if @goto != ''
        redirect_to @goto
      else        
        @subsection = 'view'
        render :action=>'index'
      end
    else
      @subsection = 'edit'
      render :action => "edit"
    end
  end
    

  def photos
    #-- Show your own pictures
    @section = 'profile'
    @participant_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.find(@participant_id)
    @photos = Photo.where(:participant_id=>@participant_id).all
    @picdir = "#{DATADIR}/photos/#{@participant_id}"
    @picurl = "/images/data/photos/#{@participant_id}"
    update_last_url
  end  
  
  def photolist
    photos
    render :partial=>'photolist', :layout=>false
  end  
  
  def picupload
    @participant_id = current_participant.id
    original_filename = params[:uploadfile].original_filename.to_s
    if original_filename != ""
      # http://wiki.rubyonrails.org/rails/pages/HowtoUploadFiles
      #params[:uploadfile].original_filename
      #params[:uploadfile].content_type
      tempfilepath = "/tmp/#{original_filename}"
      tempfilepath2 = "/tmp/#{@participant_id}_2.jpg"
      f = File.new(tempfilepath, "wb")
      f.write params[:uploadfile].read
      f.close    
      if File.exist?(tempfilepath)
        @photo = Photo.new(:participant_id=>@participant_id,:filename=>original_filename,:caption=>params[:caption])
        @photo.save!
        
        @picdir = "#{DATADIR}/photos/#{@participant_id}"
        `mkdir "#{@picdir}"` if not File.exist?(@picdir)
        @bigfilepath = "#{@picdir}/#{@photo.id}.jpg"
        @thumbfilepath = "#{@picdir}/#{@photo.id}_75.jpg"

        p = Magick::Image.read("#{tempfilepath}").first
        if p
          p.change_geometry('640x640') { |cols, rows, img| img.resize!(cols, rows) }
          p.write("#{@bigfilepath}")
        end
        
        logger.info("front#picupload converting #{tempfilepath} to #{@bigfilepath}")         

        if p and File.exist?(@bigfilepath)

      		bigpicsize = File.stat("#{@bigfilepath}").size
          iwidth = iheight = 0
          begin
            open("#{@bigfilepath}", "rb") do |fh|
              iwidth,iheight = ImageSize.new(fh.read).get_size
            end
          rescue
          end  
          logger.info("front#picupload size:#{bigpicsize} dim:#{iwidth}x#{iheight}")
        
          #-- Construct an icon image 100x100
          #`rm -f #{tempfilepath2}` if File.exist?(tempfilepath2)
        
          if iwidth >= iheight
            p.change_geometry('1000x100') { |cols, rows, img| img.resize!(cols, rows) }
          else
            p.change_geometry('100x1000') { |cols, rows, img| img.resize!(cols, rows) }
          end
          #p.write("#{tempfilepath2}")

          #if File.exist?(tempfilepath2)
            #p = Magick::Image.read("#{tempfilepath}").first
            if iwidth >= iheight
              #-- If it is a landscape picture, get the middle part
              width = iwidth * 100 / iheight
              offset = ((width - 100) / 2).to_i
              icon = p.crop(offset, 0, 100, 100)
            else
              #-- If it is a portrait picture, get the top part
              icon = p.crop(0, 0, 100, 100)
            end
            icon.write("#{@thumbfilepath}")
          #end
        
          p.destroy! if p
          icon.destroy! if icon
        
          `rm -f #{tempfilepath} #{tempfilepath2}`
        
          @photo.filesize = bigpicsize if bigpicsize
          @photo.width = iwidth if iwidth
          @photo.height = iheight if iheight
          @photo.filetype = original_filename.split('.').last
          @photo.save
        
        end
        
      end  
    end
    #responds_to_parent do
    #  render :update do |page|
    #    page << %(uploadpicturedone();)
    #  end
    #end  
    render :text=>%s(<script>window.parent.uploadpicturedone();</script>),:layout=>false  
  end  
  
  def picdelete
    #-- Delete some pictures
    @participant_id = current_participant.id
    @picdir = "#{DATADIR}/photos/#{@participant_id}"
    pix = params[:pix]
    result = ""
    if pix.class==Array
      for photo_id in pix
        `rm -f "#{@picdir}/#{photo_id}.jpg"`
        `rm -f "#{@picdir}/#{photo_id}_*"`
        photo = Photo.find(photo_id)
        photo.destroy
        result += 'Deleted'
      end
    else
      result += "No file list received. pix:#{pix.class.to_s}"  
    end
    result = "ok" if result==""
    render :text=>result, :layout=>false
  end  

  def twitauth
    #-- Try to get an authorization for the current user, to post to their twitter account
    #-- I could also use omniauth or devise. That is, if I knew how.
    #-- http://oauth.rubyforge.org/
    #-- http://cbpowell.wordpress.com/2010/10/12/twitter-oauth-and-ruby-on-rails-integrated-cookbook-style-in-the-console/
    #-- http://groups.google.com/group/ruby-twitter-gem/browse_thread/thread/29d587637afe28eb#
    #-- http://stakeventures.com/articles/2008/02/23/developing-oauth-clients-in-ruby
    #-- http://philsturgeon.co.uk/news/2010/11/using-omniauth-to-make-twitteroauth-api-requests
    #-- http://blog.brijeshshah.com/integrate-twitter-oauth-in-your-rails-application/comment-page-1/
     
    #-- Acquire a request token
    @request_token = ProfilesController.twitconsumer.get_request_token(:oauth_callback => "http://#{BASEDOMAIN}/me/twitcallback")
    session[:rtoken] = @request_token.token
    session[:rsecret] = @request_token.secret
    authorize_url = @request_token.authorize_url    # "http://api.twitter.com/oauth/authorize?oauth_token=your_request_token"
    ## http://twitter.com/oauth/request_token/oauth/authorize?oauth_token=2H3SG76EYVJkYSaxBvJ0oK1zWoofhd2nSUsSD4VAk1Y

    #use OmniAuth::Strategies::Twitter, TWITTER_CONSUMER_KEY, TWITTER_CONSUMER_SECRET
    
    logger.info("profiles#twitauth rtoken:#{session[:rtoken]} rsecret:#{session[:rsecret]} authorize_url:#{authorize_url}")
    
    #-- Send use to authorization
    #redirect_to '/auth/twitter'
    redirect_to authorize_url 
        
  end  

  def twitcallback
    #-- Callback from Twitter, after somebody authorizes themselves
    #-- This is where we get the access keys
    #-- http://cbpowell.wordpress.com/2010/10/12/twitter-oauth-and-ruby-on-rails-integrated-cookbook-style-in-the-console/
    #-- http://dev.twitter.com/pages/auth

    # params: {"oauth_token"=>"cT4jP3LWUd7RFAoVADtR9Oec4GSA2TppjVxufC6BMM", "oauth_verifier"=>"wqxxDrsBaILlGTc8CSnyvAkAdZYqt6wuik5EUdfLzSI", "controller"=>"profiles", "action"=>"twitcallback"}
    
    oauth_token = params[:oauth_token]   # Same as the request token we sent
    oauth_verifier = params[:oauth_verifier]   # What we need for the next top
    
    @request_token = OAuth::RequestToken.new(ProfilesController.twitconsumer, session[:rtoken], session[:rsecret])
    
    #-- Exchange the request token for an access token

    #atoken, asecret = oauth.authorize_from_request(rtoken, rsecret, your_pin_here)
    
    # Exchange the request token for an access token.
    @access_token = @request_token.get_access_token(:oauth_verifier => oauth_verifier)
    @response = ProfilesController.twitconsumer.request(:get, '/account/verify_credentials.json',@access_token, { :scheme => :query_string })
    case @response
    when Net::HTTPSuccess
      user_info = JSON.parse(@response.body)
      unless user_info['screen_name']
        flash[:notice] = "Authentication failed"
        redirect_to :action =>:index
        return
      end
      
      #-- We have an authorized user, save the information to the database.
      current_participant.twitter_oauth_token = @access_token.token
      current_participant.twitter_oauth_secret = @access_token.secret
      current_participant.save!
      
      # Redirect to the settings page
      redirect_to '/me/profile/settings'
    else
      
      logger.info("profiles#twitcallback Failed to get user info via OAuth")
      # The user might have rejected this application. Or there was some other error during the request.
      flash[:notice] = "Authentication failed"
      redirect_to '/me/profile/settings'
    end
    
    
  end  

  protected
  
  def self.twitconsumer
    #-- Provide a consumer object, for Twitter access
    OAuth::Consumer.new(TWITTER_CONSUMER_KEY, TWITTER_CONSUMER_SECRET, {:site=>"http://api.twitter.com/"})   
  end
  
  def geoupdate
    #-- Update geo-related fields, when saving a participant, or if one of the fields changed
    #-- Duplicate of what's in participants controller. Not good.
    if @participant.country_code.to_s != ""
      #-- Fill in the country name
      geocountry = Geocountry.find_by_iso(@participant.country_code)
      @participant.country_name = geocountry.name
    end   
    if @participant.admin2uniq.to_s != ""  
      geoadmin2 = Geoadmin2.find_by_admin2uniq(@participant.admin2uniq)
      if geoadmin2
        #-- Fill in the county (admin2) code and name
        @participant.county_code = geoadmin2.admin2_code
        @participant.county_name = geoadmin2.name
        if @participant.admin1uniq.to_i == 0
          #-- If we got the admin2 first, look up the admin1 from it
          @participant.admin1uniq = geoadmin2.admin1uniq
        end  
      end 
    end
    if @participant.admin1uniq.to_s != ""
      #-- Fill in the state (admin1) code and name
      geoadmin1 = Geoadmin1.find_by_admin1uniq(@participant.admin1uniq)
      if geoadmin1
        @participant.state_code = geoadmin1.admin1_code
        @participant.state_name = geoadmin1.name
      end
    end    
    if @participant.timezone.to_s!=''
      #-- Calculate timezone offset from UTC
      @participant.timezone_offset = TZInfo::Timezone.get(@participant.timezone).period_for_utc(Time.new).utc_offset / 3600
    end      
  end
  
#  def check_group_and_dialog  
#    if participant_signed_in? and session[:group_id].to_i == 0 and session[:dialog_id].to_i == 0
#      session[:group_id] = current_participant.last_group_id
#      session[:dialog_id] = current_participant.last_dialog_id
#      if session[:group_id].to_i > 0
#        @group_id = session[:group_id]
#        @group = Group.find_by_id(@group_id)
#        if @group
#          session[:group_name] = @group.name
#          session[:group_prefix] = @group.shortname
#          @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).find(:first)
#          @is_member = @group_participant ? true : false
#          session[:group_is_member] = @is_member
#        end
#      end
#      if session[:dialog_id].to_i > 0
#        @dialog_id = session[:dialog_id]
#        @dialog = Dialog.find_by_id(@dialog_id)
#        if @dialog
#          session[:dialog_name] = @dialog.name
#          session[:dialog_prefix] = @dialog.shortname
#        end
#      end
#    end  
#    #if session[:dialog_id].to_i > 0
#    #  @dialog = Dialog.find_by_id(session[:dialog_id])
#    #end
#  end
  
end
