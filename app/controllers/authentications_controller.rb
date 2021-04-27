# encoding: utf-8

class AuthenticationsController < ApplicationController

	layout "front"
  
  def index
    @section = 'profile'
    group_id,dialog_id = get_group_dialog_from_subdomain
    if dialog_id.to_i > 0 and not @dialog
      @dialog = Dialog.find_by_id(dialog_id)
    end
    #if @dialog and not @dialog.alt_logins
    #  redirect_to "/participants/sign_in"
    #  return
    #elsif @group and not @group.alt_logins
    #  redirect_to "/participants/sign_in"
    #  return
    #end
    @authentications = current_participant.authentications if current_participant
  end

  def create
    omniauth = request.env["omniauth.auth"]
    logger.info("authentications#create omniauth.auth:#{omniauth.to_yaml}")
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
    if authentication
      # Logging in with existing authorization that we already knew about
      flash[:notice] = "Signed in successfully."
      logger.info("authentications#create signed in")
      #sign_in_and_redirect(:participant, authentication.participant)
      sign_in(:participant, authentication.participant)
      if current_participant and not current_participant.has_required
        redirect_to '/me/profile/meta' and return
      else
        redirect_to "/dialogs/#{VOH_DISCUSSION_ID}/slider" and return
      end
    elsif current_participant
      # Adding an authorization, while already logged in
      current_participant.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'])
      current_participant.get_fields_from_omniauth(omniauth)
      current_participant.save
      flash[:notice] = "Authentication successful."
      logger.info("authentications#create #{current_participant.id} authenticated")
      redirect_to authentications_url
    else
      # They authorized with an external service, but they hadn't used it before. Which means it is a signup or they already have a regular login
      logger.info("authentications#create Trying to create new participant")
      @participant = Participant.new
      @participant.apply_omniauth(omniauth)
      logger.info("authentications#create email is #{@participant.email} after apply_omniauth")
      # First check for duplicate account
      participants = Participant.where(:email=>@participant.email)
      if participants.length > 0
        #-- We already know them by their email. Just add the new service to their account
        @participant = participants[0]
        if @participant.status == 'active' or @participants.status == 'unconfirmed'
          @participant.status = 'active'
          @participant.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'])
          @participant.get_fields_from_omniauth(omniauth)
          @participant.save
          if @participant.fb_uid.to_i >0 and not @participant.picture.exists?
            #-- Use their facebook photo, if they don't already have one.
            url = "https://graph.facebook.com/#{@participant.fb_uid}/picture?type=large"
            @participant.picture = URI.parse(url).open
            @participant.save!
          end
          sign_in(:participant, @participant)
          if omniauth['provider'] == 'facebook'
            loginname = "Facebook"
          elsif omniauth['provider'] == 'google_oauth2'
            loginname = "Google"
          else
            loginname = "Facebook"
          end
          flash[:notice] = "Authentication successful. #{loginname} login added to your existing account."
          logger.info("authentications#create #{current_participant.id} authenticated")          
          if session.has_key?(:comtag) and session.has_key?(:joincom)
            # They should be joined to a community, if they aren't already a member ?comtag=love&joincom=1
            logger.info("authentications#create joining to community #{session[:comtag]}")
            comtag = session[:comtag]
            comtag.gsub!(/[^0-9A-za-z_]/,'')
            #comtag.downcase!
            if ['VoiceOfMen','VoiceOfWomen','VoiceOfYouth','VoiceOfExperience','VoiceOfExperie','VoiceOfWisdom'].include? comtag
            elsif comtag != ''
              @participant.tag_list.add(comtag)
            end
            @participant.save
            session.delete(:joincom)
          end
          if session[:group_id].to_i > 0
            @group_id = session[:group_id]
            @group_participant = GroupParticipant.where(:group_id=>@group_id,:participant_id=>@participant.id).first
            if not @group_participant
              #-- Add them as a group member, if they aren't already a member
              @group = Group.find_by_id(@group_id)
              if @group
                @group_participant = GroupParticipant.new(:group_id=>@group_id,:participant_id=>@participant.id)
                if @group.openness == 'open'
                  @group_participant.active = true
                  @group_participant.status = 'active'
                else
                  #-- open_to_apply probably
                  @group_participant.active = false
                  @group_participant.status = 'applied'      
                end
                @group_participant.save
              end  
            end  
          end  
          if session[:dialog_id].to_i > 0
            @forum_link = "/dialogs/#{session[:dialog_id]}/slider"
            if params and params.has_key?(:comtag) and params[:comtag].to_s != ''
              @forum_link += "?comtag=" + params[:comtag]
              if params.has_key?(:joincom)
                @forum_link += "&joincom=1"
              end
            elsif session.has_key?(:comtag) and session[:comtag].to_s != ''
              @forum_link += "?comtag=" + session[:comtag]
              if session.has_key?(:joincom)
                @forum_link += "&joincom=1"
              end
            end
          elsif session.has_key?(:previous_comtag) and session[:previous_comtag].to_s != ''
            @forum_link = "/dialogs/#{VOH_DISCUSSION_ID}/slider?comtag=#{session[:previous_comtag]}"         
          elsif session[:group_id].to_i > 0
            @forum_link = "/groups/#{session[:group_id]}/forum"
          else
            @forum_link = '/groups/'
          end  
          #redirect_to authentications_url
          redirect_to @forum_link
        else  
          #-- Unless if they're not active, then show them a screen saying they'll have to log in by themselves
          render :action=>:hasaccount
        end
      else
        #-- We really don't know them. It is a signup
        session[:omniauth] = omniauth.except('extra')
        redirect_to '/front/fbjoin'
      #elsif @participant.save
      #  logger.info("authentications#create #{@participant.id} created and signed in")
      #  #-- A rudimentary account has already been created at this point. Do all the rest
      #  facebookjoin        
      #  #sign_in_and_redirect(:participant, @participant)
      #else
      #  logger.info("authentications#create couldn't save, not created, not signed in")
      #  logger.info("authentications#create notice:#{flash[:notice]} alert:#{flash[:alert]} errors:#{@participant.errors}")
      #  session[:omniauth] = omniauth.except('extra')
      #  redirect_to new_participant_registration_url
      end
    end
  end

  def destroy
    @authentication = current_participant.authentications.find(params[:id])
    @authentication.destroy
    flash[:notice] = "Successfully destroyed authentication."
    redirect_to authentications_url
  end 
  
  
end