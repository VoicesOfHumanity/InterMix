class FbappController < ApplicationController

  layout "facebook"
  
  def index
    getfbstuff

        
  end 
  
  def addform
    getfbstuff
    
  end
  
  def postjoin
    #-- Process form from an instant form. Join if necessary
    getfbstuff

    @message = params[:message].to_s
    @name = params[:name].to_s
    @email = params[:email].to_s
    @group_id = params[:group_id].to_i
    @dialog_id = params[:dialog_id].to_i
    tempfilepath = ''
    
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
      render :action=>:addform
      return
    end  
    
    if @message == ''
      flash[:alert] = "Please include a short message to show with your picture<br>"
    end  
    if @name == '' and not participant_signed_in?
      flash[:alert] = "What's your name?<br>"
    end  
    if @email == '' and not participant_signed_in?
      flash[:alert] = "Please type in your e-mail address as well<br>"
    end  
    if not params[:picfile]
      flash[:alert] = "You need to upload a picture<br>"
    end  
    if flash[:alert] != ''
      render :action=>:addform
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

    if participant_signed_in?
      @participant = current_participant
    else
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
          render :action=>:addform, :layout=>'blank'
          return
        end  
      end
    end
    
    @participant.groups << @group
 
    @item = Item.new
    @item.group_id = @group_id
    @item.dialog_id = @dialog_id
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

    @samples = Item.where("items.dialog_id=#{@dialog_id} and items.has_picture=1 and items.media_type='picture' and is_flagged!=1").includes(:participant).order("items.id desc").limit(5)

    redirect_to :action=>:showpix
  end  
  
  def showpix
    getfbstuff
    @items = Item.where("items.dialog_id=#{@dialog_id} and items.has_picture=1 and items.media_type='picture' and is_flagged!=1").includes(:participant).order("items.id desc").limit(12)
  end
  
  def search
    getfbstuff
    if params[:q].to_s != ''
      @q = params[:q]
      @items = Item.where("items.dialog_id=#{@dialog_id} and items.has_picture=1 and items.media_type='picture' and is_flagged!=1 and items.short_content like '%#{@q}%'").includes(:participant).order("items.id desc").limit(12)   
    else
      @items = []
    end
  end  
  
  def flag
    getfbstuff
    item_id = params[:id].to_i
    item = Item.find_by_id_and_dialog_id(item_id,@dialog_id)
    if item and current_participant
      item_flag = ItemFlag.create(:item_id=>item_id, :participant_id=>current_participant.id)
      item.is_flagged = true
      item.save
      render plain: 'ok'
    else
      render plain: 'notok'        
    end
  end
  
  protected
  
  def getfbstuff
    
    @group_id = 7
    @dialog_id = 2
    
    @group = Group.find(@group_id)
        
    #parameters: {
    #"fb_sig_in_iframe"=>"1", 
    #"fb_sig_locale"=>"en_US", 
    #"fb_sig_in_new_facebook"=>"1", 
    #"fb_sig_time"=>"1306879780.136", 
    #"fb_sig_added"=>"1", 
    #"fb_sig_profile_update_time"=>"1300056635", 
    #"fb_sig_expires"=>"0", 
    #"fb_sig_user"=>"511572735", 
    #"fb_sig_session_key"=>"851e95c9e619e4ade1e628e2.0-511572735", 
    #"fb_sig_ss"=>"5958dbf4dbd644c0d955251ff42db503", 
    #"fb_sig_cookie_sig"=>"08b46ae1067357fa1ffd9e6dcdf927b9", 
    #"fb_sig_ext_perms"=>"offline_access,email", 
    #"fb_sig_country"=>"fr", 
    #"fb_sig_api_key"=>"3a7004b9f9a741873f7026e1f66226bd", 
    #"fb_sig_app_id"=>"151526481561013", 
    #"fb_sig"=>"4bdec3a4ece9a952b2f7be4326996488", 
    #"controller"=>"fbapp", 
    #"action"=>"index"}
    # OR:
    # {"signed_request"=>"h8GIdrWYiPmSVXxYLmbnFDB9izEn2ZGBTUJuKS9wUlU.eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsImV4cGlyZXMiOjAsImlzc3VlZF9hdCI6MTMwODA5MDIxNywib2F1dGhfdG9rZW4iOiIxNTE1MjY0ODE1NjEwMTN8ODUxZTk1YzllNjE5ZTRhZGUxZTYyOGUyLjAtNTExNTcyNzM1fExQMW5mRTBmY3lIMG9TdUlnYUpYVVZoR0JPQSIsInBhZ2UiOnsiaWQiOiIxMzU1ODMyNjk3ODkzNjAiLCJsaWtlZCI6dHJ1ZSwiYWRtaW4iOnRydWV9LCJ1c2VyIjp7ImNvdW50cnkiOiJmciIsImxvY2FsZSI6ImVuX1VTIiwiYWdlIjp7Im1pbiI6MjF9fSwidXNlcl9pZCI6IjUxMTU3MjczNSJ9"}
    
    # signed_request: http://developers.facebook.com/docs/authentication/signed_request/
    if params[:signed_request]
      rg = RestGraph.new({:app_id => FACEBOOK_APP_ID, :secret => FACEBOOK_API_SECRET})
      parsed_request = rg.parse_signed_request!(params['signed_request'])
      # {"algorithm"=>"HMAC-SHA256", "expires"=>0, "issued_at"=>1308090217, "oauth_token"=>"151526481561013|851e95c9e619e4ade1e628e2.0-511572735|LP1nfE0fcyH0oSuIgaJXUVhGBOA", "page"=>{"id"=>"135583269789360", "liked"=>true, "admin"=>true}, "user"=>{"country"=>"fr", "locale"=>"en_US", "age"=>{"min"=>21}}, "user_id"=>"511572735", "sig"=>"\x87\xC1\x88v\xB5\x98\x88\xF9\x92U|X.f\xE7\x140}\x8B1'\xD9\x91\x81MBn)/pRU"}
      
    end
    
    @newlogin = false

    if not participant_signed_in?   
      fb_user_id = params[:fb_sig_user].to_i
      #a = Authentications.where(:provider=>"facebook",:uid=>fb_user_id)
      #if a.length > 0
      #  participant_id = a[0].participant_id
      #end

      authentication = Authentication.find_by_provider_and_uid('facebook', fb_user_id)
      if authentication
        # Logging in with existing authorization that we already knew about
        flash[:notice] = "Signed in successfully."
        logger.info("authentications#create signed in")
        @newlogin = true
        sign_in_and_redirect(:participant, authentication.participant)
      end
    end
    
    @samples = Item.where("items.dialog_id=#{@dialog_id} and items.has_picture=1 and items.media_type='picture' and is_flagged!=1").includes(:participant).order("items.id desc").limit(5)
    
  end       
    
  def stored_location_for(resource_or_scope)
    # make devise not remember where they were trying to go
    nil
  end

  def after_sign_in_path_for(resource_or_scope)
    # send them here after they log in
    '/fbapp/showpix'
  end  
    
end
