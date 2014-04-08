# encoding: utf-8

class AuthenticationsController < ApplicationController

	layout "front"
  
  def index
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
      sign_in_and_redirect(:participant, authentication.participant)
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
        #-- We already know them by their email. Just add Facebook to their account
        @participant = participants[0]
        if @participant.status == 'active' or @participants.status == 'unconfirmed'
          @participant.status = 'active'
          @participant.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'])
          @participant.get_fields_from_omniauth(omniauth)
          @participant.save
          sign_in(:participant, @participant)
          flash[:notice] = "Authentication successful. Facebook login added to your existing account."
          logger.info("authentications#create #{current_participant.id} authenticated")
          if session[:dialog_id].to_i > 0
            @forum_link = "/dialogs/#{session[:dialog_id]}/forum"
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