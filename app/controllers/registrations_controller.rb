# encoding: utf-8

class RegistrationsController < Devise::RegistrationsController
  layout "front"

  def create
    logger.debug("Registrations#create")
    super
    session[:omniauth] = nil unless @participant.new_record?
  end
  
  private
  
  def build_resource(*args)
    logger.debug("Registrations#build_resource")
    super
    if session[:omniauth]
      @participant.apply_omniauth(session[:omniauth])
      @participant.valid?
    end
  end
end