# encoding: utf-8

class RegistrationsController < Devise::RegistrationsController
  layout "front"

  def new
    logger.debug("Registrations#new")
    super
  end

  def create
    logger.debug("Registrations#create")
    
    super

    @metamaps = Metamap.where(:global_default=>true)

    
    session[:omniauth] = nil unless @participant.new_record?
  end
  
  private
  
  def build_resource(*args)
    logger.debug("Registrations#build_resource")
    @metamaps = Metamap.where(:global_default=>true)
    super
    if session[:omniauth]
      @participant.apply_omniauth(session[:omniauth])
      @participant.valid?
    end
  end
end