# encoding: utf-8

class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  
  def method_missing(provider)
    if !Participant.omniauth_providers.index(provider).nil?

      auth = env["omniauth.auth"]
      
#      render :text => auth.inspect

#if false
    
      if current_participant
        current_participant.participant_tokens.find_or_create_by_provider_and_uid(auth['provider'], auth['uid'])
         flash[:notice] = "Authentication successful"
         #redirect_to edit_participant_registration_path
         render plain: auth.to_yaml
      else
    
        authentication = ParticipantToken.find_by_provider_and_uid(auth['provider'], auth['uid'])
   
        if authentication
          flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => auth['provider']
          sign_in_and_redirect(:participant, authentication.participant)
          #sign_in_and_redirect @user, :event => :authentication
          render plain: auth.to_yaml
        else
          #session["devise.#{provider}_data"] = env["omniauth.auth"]
          redirect_to new_participant_registration_url
        end
      end
#end      
    end
  end
  
end