require 'openssl'

class ProfilesController < ApplicationController
  
  layout "front"
  before_action :authenticate_user_from_token!
  before_action :authenticate_participant!, :check_group_and_dialog
  
  def index
    @section = 'profile'
    @psection = 'profile'
    profile
    update_last_url
  end  
  
  def profile
    #-- show your own profile
    @section = 'profile'
    @psection = 'profile'
    @subsection = 'view'
    @participant_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.includes(:metro_area).find(@participant_id)
    render :action=>:index
    update_last_url
  end  
  
  def edit
    @section = 'profile'
    @psection = 'profile'
    @subsection = 'edit'
    @profile_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.find_by_id(@profile_id)
    @participant.new_signup = false
    @participant.save
    if @participant.direct_email_code.to_s == ''
      trycode = Digest::MD5.hexdigest(Time.now.to_f.to_s)[6,10]
      matches = Participant.where("direct_email_code='#{trycode}'")
      if matches and matches.length > 0
        logger.info("profiles#settings duplicate direct_email_code:#{trycode}")
      else
        @participant.direct_email_code = trycode
        @participant.save
      end
    end
    if @participant.country_code2 == '_I'
      # If indigenous as country, add to religion, if not there
      has_indig = false
      for p_r in @participant.participant_religions
        if p_r.religion.name == 'Indigenous'
          has_indig = true
        end 
      end
      if not has_indig
        logger.info("profiles#settings adding missing indigenous religion")
        religion = Religion.find_by_name('Indigenous')
        if religion
          ParticipantReligion.create(participant_id: @participant.id, religion_id: religion.id)
        end
      end
    end
    session[:has_required] = @participant.has_required
    if @participant.country_code.to_s != ''
      @metro_areas = MetroArea.where(:country_code=>@participant.country_code).order(:name).collect{|r| [r.name,r.id]}
    else  
      @metro_areas = MetroArea.joins(:geocountry).order("geocountries.name,metro_areas.name").collect{|r| ["#{r.geocountry.name}: #{r.name}",r.id]}
    end
    @major_communities = Community.where(major: true).order(:fullname)
    @more_communities = Community.where(more: true).order(:fullname)
    #@ungoals_communities = Community.where(ungoals: true).order(:fullname)
    #@sustdev_communities = Community.where(sustdev: true).order(:fullname)
    flash.now[:alert] = "Some required fields need to be entered" if not session[:has_required]
    @group = Group.find_by_id(session[:group_id]) if not @group and session[:group_id].to_i > 0
    if session[:dialog_id].to_i > 0
      @forum_link = "/dialogs/#{session[:dialog_id]}/slider"
    elsif @group
      @forum_link = "/groups/#{@group.id}/forum"
    else
      @forum_link = ''
    end  
  end

  def settings
    @section = 'profile'
    @psection = 'profile'
    @subsection = 'settings'
    @profile_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.find(@profile_id)
    if @participant.direct_email_code.to_s == ''
      trycode = Digest::MD5.hexdigest(Time.now.to_f.to_s)[6,10]
      matches = Participant.where("direct_email_code='#{trycode}'")
      if matches and matches.length > 0
        logger.info("profiles#settings duplicate direct_email_code:#{trycode}")
      else
        @participant.direct_email_code = trycode
        @participant.save
      end
    end  
    update_last_url
  end
  
  def missingmeta
    #-- A screen for filling in any missing (mainly) meta information we need. That's normally used right after a Facebook signup
    @section = 'profile'
    @psection = 'profile'
    @subsection = 'meta'
    @profile_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.find_by_id(@profile_id)
    @participant.new_signup = false
    @participant.save

    @group_id,@dialog_id = get_group_dialog_from_subdomain
    @group_id = session[:group_id].to_i if @group_id.to_i == 0
    @group = Group.find_by_id(@group_id) if not @group and @group_id > 0

    if @participant.country_code.to_s != ''
      @metro_areas = MetroArea.where(:country_code=>@participant.country_code).order(:name).collect{|r| [r.name,r.id]}
    else  
      @metro_areas = MetroArea.joins(:geocountry).order("geocountries.name,metro_areas.name").collect{|r| ["#{r.geocountry.name}: #{r.name}",r.id]}
    end

    #if session[:dialog_id].to_i > 0
    #  @forum_link = "/dialogs/#{session[:dialog_id]}/slider"
    #elsif @group
    #  @forum_link = "/groups/#{@group.id}/forum"
    #else
    #  @forum_link = '/groups/'
    #end
    @forum_link = "/dialogs/#{VOH_DISCUSSION_ID}/slider"  
    
  end  
  
  
  def update
    @section = 'profile'
    @psection = 'profile'
    @subsection = params[:subsection].to_s
    @profile_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.find(@profile_id)
    logger.info("profiles#update #{@participant.id}")
    @oldparticipant = @participant.dup
    @old_country_code = @participant.country_code.clone
    @old_country_code2 = @participant.country_code2.clone
    @old_city_uniq = @participant.city_uniq.clone
    @old_gender_id = @participant.gender_id
    @old_generation_id = @participant.generation_id
    @goto = params[:goto]  # Maybe a (forum) link to continue to after saving
        
    @participant.has_participated = true
    
    flash.now[:alert] = ''
    flash.now[:notice] = ''

    emailchanged = false
    if params[:participant] and params[:participant][:email] and params[:participant][:email] == ''
      flash.now[:alert] += "You can't remove the email address."
      params[:participant][:email] = @participant.email      
    elsif params[:participant] and params[:participant][:email] and params[:participant][:email] != @participant.email
      if not params[:participant][:email] =~ /^[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,4}$/
        flash.now[:alert] += "#{params[:participant][:email]} doesn't look like a valid e-mail address<br>"
        params[:participant][:email] = @participant.email      
      else
        dup = Participant.where("email='#{params[:participant][:email]}' and id!=#{@participant.id}").first
        if dup
          flash.now[:alert] += "There is already another account with the email address #{params[:participant][:email]}, so you can't use that<br>"
          params[:participant][:email] = @participant.email      
        else
          emailchanged = true
          old_email = @participant.email
        end  
      end  
    end  

    @participant.assign_attributes(participant_params) if params[:participant]
    
    @participant.old_email = old_email if emailchanged

    if params[:participant]
      flash.now[:alert] += 'A name is required<br>' if params[:participant].has_key?(:first_name) and @participant.first_name.to_s == '' and @participant.last_name.to_s == ''
      flash.now[:alert] += 'Country is required<br>' if params[:participant].has_key?(:country_code) and @participant.country_code.to_s == ''
      flash.now[:alert] += 'Visibility is required<br>' if params[:participant].has_key?(:visibility) and @participant.visibility.to_s == ''
      flash.now[:alert] += 'Personal message e-mail preference is required<br>' if params[:participant].has_key?(:private_email) and @participant.private_email.to_s == ''
      flash.now[:alert] += 'System message e-mail preference is required<br>' if params[:participant].has_key?(:system_email) and @participant.system_email.to_s == ''
      flash.now[:alert] += 'Forum posting e-mail preference is required<br>' if params[:participant].has_key?(:forum_email) and @participant.forum_email.to_s == ''
    end

    # Save any tags from checkboxes. NB: Taken care of in js, adding directly to tag_list. No longer!
    if params[:check]
      DEFAULT_COMMUNITIES.each do |tag,desc|
        #if params[:check].has_key?(tag)
          if params[:check][tag].to_i == 1
            @participant.tag_list.add(tag)
          else
            @participant.tag_list.remove(tag)
          end
        #end
      end
    end

    if flash.now[:alert] == ""
      logger.info("profiles#update saving basic fields")
      @participant.save!
    else
      logger.info("profiles#update not saving yet, because there are issues")
    end
    
    # religions
    logger.info("profiles#update religions:#{params[:religions]}")
    rchange = false
    got_religions = []
    # remove those unchecked
    for p_r in @participant.participant_religions
      if not params[:religions] or not params[:religions].include?(p_r.religion_id.to_s)
        tagname = p_r.religion ? p_r.religion.shortname : ''
        logger.info("profiles#update religion #{p_r.religion_id} removed")
        p_r.destroy
        @participant.tag_list.remove(tagname) if tagname != ''
        rchange = true
      end
    end
    @participant.save! if rchange
    rchange = false
    if params[:religions]
      # Add the new ones
      for r_id in params[:religions]
        r_id = r_id.to_i
        p_r = ParticipantReligion.where(participant_id: @participant.id, religion_id: r_id).first
        if not p_r
          r = Religion.find_by_id(r_id)
          if r
            logger.info("profiles#update religion #{r.id}:#{r.name} added")
            if params.has_key?("religion_denom_#{r.id}")
              religion_denomination = params["religion_denom_#{r.id}"]
            else
              religion_denomination = ''
            end
            ParticipantReligion.create(participant_id: @participant.id, religion_id: r_id, religion_denomination: religion_denomination)
            @participant.tag_list.add(r.shortname)
            got_religions << r.id
            rchange = true
          end
        end
      end
    end
    @participant.save! if rchange
    @participant.participant_religions.reload
    rchange = false
    has_indigenous = false
    for p_r in @participant.participant_religions
      got_religions << p_r.religion_id
      if p_r.religion and params.has_key?("religion_denom_#{p_r.religion_id}")
        if params["religion_denom_#{p_r.religion_id}"].to_s != p_r.religion_denomination
          logger.info("profiles#update religion #{p_r.religion_id}:#{p_r.religion.name} updating denomination to #{params["religion_denom_#{p_r.religion_id}"]}")
          p_r.religion_denomination = params["religion_denom_#{p_r.religion_id}"].to_s
          p_r.save
          rchange = true
        end
      end
      if p_r.religion
        if not @participant.tag_list_downcase.include?(p_r.religion.shortname.downcase)
          @participant.tag_list.add(p_r.religion.shortname)
          rchange = true
        end
        community = Community.where("(context='religion' and context_code='#{p_r.religion.id}') or (context2='religion' and context_code2='#{p_r.religion.id}')").first
        tagname = p_r.religion.shortname
        if not community and tagname.downcase != 'indigenous'          
          community = Community.create(tagname: tagname, context: 'religion', context_code: p_r.religion.id, fullname: p_r.religion.name)
          rchange = true
        end
        if community
          conversation_communities = ConversationCommunity.where(conversation_id: RELIGIONS_CONVERSATION_ID, community_id: community.id)
          if conversation_communities.length == 0
            conversation = Conversation.find_by_id(RELIGIONS_CONVERSATION_ID)
            if conversation
              conversation.communities << community
            end
          end          
        end
        if p_r.religion.name == 'Indigenous'
          has_indigenous = true
        end
      end
    end
    @participant.save! if rchange
    rchange = false
    logger.info("profiles#update have these religions: #{got_religions}")
    # Remove any unmentioned religions from tags
    religions = Religion.all
    for r in religions
      if not got_religions.include?(r.id)
        tagname = r.shortname
        if @participant.tag_list_downcase.include?(tagname.downcase)
          @participant.tag_list.remove(tagname)
          logger.info("profiles#update removing religion #{tagname} from tags")
        end
      end
    end
    if has_indigenous
      # If they have the indigenous religion, add them to nations too, if they don't already have two nations
      if @participant.country_code2.to_s == '' and @participant.country_code2 != '_I' and @participant.country_code != '_I'
        @participant.country_code2 = '_I'
      end
    end

    # Save any metamap assignments
    if params[:meta]
      metamap_nodes = @participant.metamap_nodes_h  # Any previous settings
      @participant.metamaps_h.each do |metamap_id,metamap_name,metamap|
        val = params[:meta]["#{metamap_id}"].to_i
        if metamap.binary
          # The value is 1/0 for true/false. Corresponding to two different nodes
          if params[:meta].has_key?("#{metamap_id}")
            # Look up the matching node
            if val == 1
              metamap_node = MetamapNode.where(metamap_id: metamap_id, binary_on: true).first
              if metamap_node
                val = metamap_node.id
              else
                val = 0
              end
            else
              metamap_node = MetamapNode.where(metamap_id: metamap_id, binary_on: false).first
              if metamap_node
                val = metamap_node.id
              else
                val = 0
              end
            end
            # val is now the node id, rather than 1/0
            if val > 0
              mnp = MetamapNodeParticipant.where(:metamap_id=>metamap_id,:participant_id=>@participant.id).first
              if mnp
                mnp.metamap_node_id = val
                mnp.save
              else
                MetamapNodeParticipant.create(:metamap_id=>metamap_id,:metamap_node_id=>val,:participant_id=>@participant.id)
              end 
            end 
          elsif metamap.global_default
            flash.now[:alert] += "#{metamap_name} is required by InterMix<br>"
          else
            flash.now[:alert] += "#{metamap_name} is required by one of the groups or discussions you're in<br>"             
          end
        else
          # The value would be a node number normally
          if val > 0
            mnp = MetamapNodeParticipant.where(:metamap_id=>metamap_id,:participant_id=>@participant.id).first
            if mnp
              mnp.metamap_node_id = val
              mnp.save
            else
              MetamapNodeParticipant.create(:metamap_id=>metamap_id,:metamap_node_id=>val,:participant_id=>@participant.id)
            end  
          elsif not params[:meta].has_key?("#{metamap_id}") and metamap_nodes[metamap_id] and metamap_nodes[metamap_id][1].to_i > 0
            # We didn't get it, but it is already filled in, so no problem
          elsif metamap.global_default or metamap_id==3 or metamap_id==5   
             flash.now[:alert] += "#{metamap_name} is required by InterMix<br>"
          else
            flash.now[:alert] += "#{metamap_name} is required by one of the groups or discussions you're in<br>"             
          end
        end
      end 
    end    
    
    # Update gender and generation communities, if necessary  
    @participant = Participant.find_by_id(@participant.id)  
    p = @participant
    logger.info("profiles#update gender_id:#{p.gender_id} generation_id:#{p.generation_id}")
    if p.gender_id != @old_gender_id
      logger.info("profiles#update gender changed #{@old_gender_id} -> #{p.gender_id}")
      oldcom = Community.where(context: 'gender', context_code: @old_gender_id).first
      if oldcom
        logger.info("profiles#update remove old gender:#{@old_gender_id}/#{oldcom.tagname}")
        p.tag_list.remove(oldcom.tagname)
      else
        logger.info("profiles#update old gender community not found")
      end
    end
    if p.generation_id != @old_generation_id
      logger.info("profiles#update generation changed #{@old_generation_id} -> #{p.generation_id}")
      oldcom = Community.where(context: 'generation', context_code: @old_generation_id).first
      if oldcom
        logger.info("profiles#update remove old generation:#{@old_generation_id}/#{oldcom.tagname}")
        p.tag_list.remove(oldcom.tagname)
      else
        logger.info("profiles#update old generation community not found")
      end
    end
    if p.gender_id > 0
      com = Community.where(context: 'gender', context_code: p.gender_id).first
      if com and not p.tag_list_downcase.include?(com.tagname.downcase)
        logger.info("profiles#update adding new gender:#{p.gender_id}/#{com.tagname}")
        p.tag_list.add(com.tagname)
      end
    end
    if p.generation_id > 0
      com = Community.where(context: 'generation', context_code: p.generation_id).first
      if com and not p.tag_list_downcase.include?(com.tagname.downcase)
        logger.info("profiles#update adding new generation:#{p.generation_id}/#{com.tagname}")
        p.tag_list.add(com.tagname)
      end
    end
    
    p.save!
    
    # Remove any genders and generatioins other than the one we have
    gencoms = Community.where(context: 'gender')
    for gcom in gencoms
      if gcom.context_code.to_i != p.gender_id and p.tag_list_downcase.include?(gcom.tagname.downcase)
        logger.info("profiles#update removing not used gender:#{gcom.id}/#{gcom.tagname}")
        #p.tag_list.remove(gcom.tagname)
        for tag in p.tag_list
          if tag.downcase == gcom.tagname.downcase
            p.tag_list.remove(tag)
          end
        end
      end
    end
    gencoms = Community.where(context: 'generation')
    for gcom in gencoms
      if gcom.context_code.to_i != p.generation_id and p.tag_list_downcase.include?(gcom.tagname.downcase)
        logger.info("profiles#update removing not used generation:#{gcom.id}/#{gcom.tagname}")
        #p.tag_list.remove(gcom.tagname)
        for tag in p.tag_list
          if tag.downcase == gcom.tagname.downcase
            p.tag_list.remove(tag)
          end
        end
      end
    end

    p.save!
    
    @major_communities = Community.where(major: true).order(:fullname)
    @ungoals_communities = Community.where(ungoals: true).order(:fullname)
    @sustdev_communities = Community.where(sustdev: true).order(:fullname)

    if flash.now[:alert] != ""
      @participant = Participant.find_by_id(@participant.id)
      if @subsection == 'meta'
        @forum_link = params[:forum_link]
        render :action => "missingmeta"        
      else  
        @subsection = 'edit'
        render :action => "edit"
      end  
      return
    end
    
    if @participant.save

      geoupdate
      
      if @participant.private_key.to_s == ''
        rsa_key = OpenSSL::PKey::RSA.new(2048)
        @participant.private_key = rsa_key.to_pem
        @participant.public_key = rsa_key.public_key.to_pem
        @participant.save
      end
      
      if @participant.twitter_username == '' and @participant.twitter_oauth_token != ''
        @participant.twitter_oauth_token = ''
        @participant.twitter_oauth_secret = ''
        @participant.save
      end  
      
      @alert = ""
      if @subsection == 'settings'
       flash.now[:notice] += "OK New Settings have been saved.<br>"
      else
        flash.now[:notice] += "Your profile has been updated.<br>"
      end
      
      if emailchanged
        @cdata = {}
        @cdata['email'] = @participant.email
        subject = "Your InterMix email address has been changed"
        html_content = "<p>This is a test of your new InterMix email address. If you received this, all is good.</p>"
        emailmess = SystemMailer.template(SYSTEM_SENDER, @participant.email, subject, html_content, @cdata)
        flash.now[:notice] += "A test message has been sent to your new email address, #{@participant.email}. If it does not arrive in the next two or three minutes, please first check your spam folder, and if it is not there, then double check to make sure there were no typos in the new email you just provided.<br>"        
        begin
          emailmess.deliver
        rescue Exception => e
          logger.info("profiles#{update} FAILED delivering email to #{@participant.email}: #{e}")
          flash[:notice] += "Failed to send you a test message to #{@participant.email}<br>"
          return if performed?     # strange bug, where postmark error triggers a double-render error
        end
      end
      
      #-- Update the setting for whether required fields were entered or not
      session[:has_required] = @participant.has_required
      
      if @goto.to_s != ''
        redirect_to @goto and return
      else        
        @subsection = 'view'
        #render :action=>'index' and return
        redirect_to '/me/profile'
        return
      end
    else
      @subsection = 'edit'
      render :action => "edit" and return
    end
  end
  
  def password
    @section = 'profile'
    @psection = 'profile'
    @subsection = 'password'
    @profile_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.find(@profile_id) 
    update_last_url
  end
    
  def update_password
    old_pass = params[:old_pass].to_s
    new_pass = params[:new_pass].to_s
    new_pass_confirm = params[:new_pass_confirm].to_s
    flash[:alert] = ""
    flash[:notice] = ""
    if new_pass != ''
      if old_pass == ''
        flash[:alert] += "Please enter your old password if you want to change it."
      elsif not current_participant.valid_password?(old_pass)
        flash[:alert] += "That doesn't seem to be the right password."
      elsif new_pass_confirm == ''
        flash[:alert] += "Please enter the new password a second time if you want to change it."
      elsif new_pass_confirm != new_pass
        flash[:alert] += "The two passwords don't match."
      else  
        current_participant.password = new_pass
        current_participant.save
        flash.now[:notice] = "Password changed."
        redirect_to '/me/profile' and return
      end
      redirect_to '/me/profile/password' and return
    end    
  end  
    
  def api_get_user_info
    #-- Return basic user information for the settings screen on app
    ret = {'status': '', 'country_code': '', 'admin1uniq': '', 'city': '', 'gender': 0, 'age': 0, 'regions': []}
    @participant = Participant.find(params[:id])
    if @participant
      ret['country_code'] = @participant.country_code
      ret['country_name'] = @participant.geocountry ? @participant.geocountry.name : ''
      ret['admin1uniq'] = @participant.admin1uniq
      ret['admin1_name'] = @participant.geoadmin1 ? @participant.geoadmin1.name : ''
      ret['city'] = @participant.city
      ret['gender'] = @participant.gender_id
      ret['gender_name'] = @participant.gender
      ret['age'] = @participant.generation_id
      ret['age_name'] = @participant.generation
    end    
    # Provide the choices of regions for their country
    ret['regions'] = Geoadmin1.where("country_code='#{@participant.country_code}' and admin1_code!='00'").order("name").collect {|r| {key: r.admin1uniq,label: r.name}}
    render json: ret 
  end
  
  def api_save_user_info
    #-- Save some user info from the app
    #@participant = Participant.find(params[:id])
    @participant = current_participant
    city = params['city']
    nation = params['nation']
    region = params['region']
    age = params['age'].to_i
    gender = params['gender'].to_i
    @participant.city = city
    @participant.country_code = nation
    @participant.country_name = @participant.geocountry ? @participant.geocountry.name : ''
    @participant.admin1uniq = region
    geoadmin1 = Geoadmin1.find_by_admin1uniq(@participant.admin1uniq)
    if geoadmin1
      @participant.state_code = geoadmin1.admin1_code
      @participant.state_name = geoadmin1.name
    end
    if gender.to_i > 0
      mnp = MetamapNodeParticipant.where(metamap_id: 3, participant_id: @participant.id).first
      if mnp
        mnp.metamap_node_id = gender
        mnp.save!
      else
        MetamapNodeParticipant.create(metamap_id: 3, metamap_node_id: gender, participant_id: @participant.id)
      end
    end
    if age.to_i > 0
      mnp = MetamapNodeParticipant.where(metamap_id: 5, participant_id: @participant.id).first
      if mnp
        mnp.metamap_node_id = age
        mnp.save!
      else
        MetamapNodeParticipant.create(metamap_id: 5, metamap_node_id: age, participant_id: @participant.id)
      end
    end
    begin
      @participant.save!
      render json: {'status': 'ok'}
    rescue
      render json: {'status': 'error'}      
    end
  end

  def photos
    #-- Show your own pictures
    @section = 'profile'
    @psection = 'profile'
    @participant_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.find(@participant_id)
    @photos = Photo.where(:participant_id=>@participant_id)
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
    result = {'files' => []}
    original_filename = params[:uploadfile].original_filename.to_s
    if original_filename != ""
      # http://wiki.rubyonrails.org/rails/pages/HowtoUploadFiles
      #params[:uploadfile].original_filename
      #params[:uploadfile].content_type
      fileresult = {'name' => original_filename}
      tempfilepath = "/tmp/#{original_filename}"
      tempfilepath2 = "/tmp/#{@participant_id}_2.jpg"
      f = File.new(tempfilepath, "wb")
      f.write params[:uploadfile].read
      f.close    
      if File.exist?(tempfilepath)
        @photo = Photo.new(:participant_id=>@participant_id,:filename=>original_filename,:caption=>params[:caption])
        @photo.save!
        
        @picurl = "/images/data/photos/#{@participant_id}"
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
        
          if iwidth.to_i >= iheight.to_i and iheight.to_i > 0
            p.change_geometry('1000x100') { |cols, rows, img| img.resize!(cols, rows) }
          else
            p.change_geometry('100x1000') { |cols, rows, img| img.resize!(cols, rows) }
          end
          #p.write("#{tempfilepath2}")

          #if File.exist?(tempfilepath2)
            #p = Magick::Image.read("#{tempfilepath}").first
            if iwidth.to_i >= iheight.to_i and iheight.to_i > 0
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
          filetype = original_filename.split('.').last
          if filetype.length <= 3
            @photo.filetype = filetype
          else
            @photo.filetype = 'jpg'
          end
          @photo.save
          
          fileresult['size'] = @photo.filesize    
          fileresult['url'] = "#{@picdir}/#{@photo.id}.jpg"  
        else
          logger.info("profiles#picupload #{@bigfilepath} not found")
          fileresult['error'] = "Converted file not found"
        end
      else  
        fileresult['error'] = "Uploaded file not found"
      end
    else
      fileresult['error'] = "Uploaded file not found"      
    end
    result['files'] << fileresult
    #responds_to_parent do
    #  render :update do |page|
    #    page << %(uploadpicturedone();)
    #  end
    #end  
    #render plain: %s(<script>window.parent.uploadpicturedone();</script>)  
    render :json=>result, :layout=>false
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
    render plain: result
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
    @request_token = ProfilesController.twitconsumer.get_request_token(:oauth_callback => "https://#{BASEDOMAIN}/me/twitcallback")
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
  
  def comtag
    #-- Join or leave a tag
    comtag = params[:comtag]
    which = params[:which]    
    logger.info("profiles#comtag #{which} #{comtag}")
    if which == 'join'
      comtag.gsub!(/[^0-9A-za-z_]/,'')
      #comtag.downcase!
      if ['VoiceOfMen','VoiceOfWomen','VoiceOfYouth','VoiceOfExperience','VoiceOfExperie','VoiceOfWisdom'].include? comtag
      elsif comtag != ''
        logger.info("profiles#comtag adding #{comtag} for user")
        current_participant.tag_list.add(comtag)
        com = Community.where(tagname: comtag).first
        if not com
          com = Community.create(tagname: comtag)
          com.save
        end
        while com.is_sub do
          #-- Join all further up communities
          parent = Community.find_by_id(com.sub_of)
          current_participant.tag_list.add(parent.tagname)
          com = parent
        end
      end
    else
      logger.info("profiles#comtag removing #{comtag} for user")
      current_participant.tag_list.remove(comtag)
      current_participant.tag_list.each do |tag|
        if tag.downcase == comtag.downcase
          current_participant.tag_list.remove(tag)
        end
      end
    end
    current_participant.save!
    
    #-- See if it affected the perspective in any conversations
    community = Community.find_by_tagname(comtag)
    for conversation in community.conversations    
      # Pick an appropriate perspective for that conversation
      perspectives = {}    
      for com in conversation.communities
        if current_participant.tag_list.include?(com.tagname)
          perspectives[com.tagname] = com.fullname
        end
      end
      if perspectives.length == 0
        conversation.perspective = 'outsider'
      elsif perspectives.length == 1
        conversation.perspective = perspectives.keys[0]
      elsif which == 'join'
        conversation.perspective = comtag
      else
        conversation.perspective = perspectives.keys[0]
      end
      session["cur_perspective_#{conversation.id}"] = conversation.perspective 
    end   
    
    render plain: 'ok'
  end
  
  def invite
    #-- Invite screen
    @section = 'profile'
    @psection = 'mail'
    @messtext = ''
    @participant = Participant.includes(:idols).find(current_participant.id)  
    @members = Participant.order("first_name,last_name")  
  end  
  
  def invitedo
    #-- Invite more members
    @section = 'profile'
    @psection = 'invite'
    logger.info("profiles#invitedo")  
    flash[:notice] = ''
    flash[:alert] = ''
    
    @group_id = GLOBAL_GROUP_ID
    @group = Group.includes(:group_participants=>:participant).find(@group_id)

    @new_text = params[:new_text].to_s
    @messtext = params[:messtext].to_s    
    @messtext += render_to_string :partial=>"invite_default", :layout=>false

    @cdata = {}
    @cdata['current_participant'] = current_participant
    @cdata['group'] = @group if @group
    @cdata['group_logo'] = "https://#{BASEDOMAIN}#{@group.logo.url}" if @group.logo.exists?
    @cdata['logo'] = "https://#{BASEDOMAIN}#{@group.logo.url}" if @group.logo.exists?
    @cdata['domain'] = Rails.env!='development' ? "voh.#{ROOTDOMAIN}" : "#{BASEDOMAIN}"

    #-- Some non-members, supposedly. But catch if some of them already are members.
    lines = @new_text.split(/[\r\n]+/)
    flash[:notice] += "#{lines.length} lines<br>"
    x = 0
    for line in lines do
      email = line.strip

      @recipient = Participant.find_by_email(email)
      if @recipient
        flash[:notice] += "#{email} is already a member<br>"
      elsif not email =~ /^[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,4}$/
        flash[:notice] += "\"#{email}\" doesn't look like a valid e-mail address<br>"  
      else
        @cdata['email'] = email
        @cdata['joinlink'] = "https://#{@cdata['domain']}/djoin?email=#{email}"

        if @messtext.to_s != ''
          template = Liquid::Template.parse(@messtext)
          html_content = template.render(@cdata)
        else
          html_content = "<p>You have been invited by #{current_participant.email_address_with_name} to join Voices of Humanity<br/>"
          html_content += "Go <a href=\"#{@cdata['joinlink']}\">here</a> to fill in your information and join.<br>"
          html_content += "</p>"            
        end
      
        subject = "#{current_participant.name} invites you to Voices of Humanity"

        emailmess = SystemMailer.template("questions@intermix.org", email, subject, html_content, @cdata)

        logger.info("profiles#invitedo delivering email to #{email}")
        begin
          emailmess.deliver
          flash[:notice] += "An invitation message was sent to #{email}<br>"
        rescue
          logger.info("profiles#invitedo FAILED delivering email to #{email}")
          flash[:notice] += "Failed to send an invitation to #{email}<br>"
        end
      end

    end
      
    redirect_to :action => :invite
  end

  protected
  
  def self.twitconsumer
    #-- Provide a consumer object, for Twitter access
    OAuth::Consumer.new(TWITTER_CONSUMER_KEY, TWITTER_CONSUMER_SECRET, {:site=>"http://api.twitter.com/"})   
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
#          @group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",@group.id,current_participant.id).first
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
  
  def participant_params
    params.require(:participant).permit(
    :picture,
    :first_name, :last_name, :title, :self_description, :address1, :address2, :city, :admin2uniq, :country_code, :country_name, :country_code2, :country_name2, :admin1uniq, :state_code, :state_name, :county_code, :county_name, :zip, :phone,
    :latitude, :longitude, :timezone, :timezone_offset, :metropolitan_area, :metro_area_id, :bioregion, :bioregion_id, :faith_tradition, :faith_tradition_id, :political, :political_id, :email, :visibility,
    :wall_visibility, :item_to_forum, :twitter_post, :twitter_username, :twitter_oauth_token, :twitter_oauth_secret, :forum_email, :group_email, :subgroup_email, :private_email, :system_email, :no_email, :handle,
    :indigenous, :other_minority, :veteran, :interfaith, :refugee, :tag_list, :mycom_email, :othercom_email, :city_uniq, :country_iso3, :country2_iso3
    )
  end

end
