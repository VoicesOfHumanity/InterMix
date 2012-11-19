# encoding: utf-8

class RegistrationsController < Devise::RegistrationsController
  layout "front"

  def new
    logger.debug("Registrations#new")
    super
  end

  def create
    logger.debug("Registrations#create")
    
    #-- Do a bit of validation
    flash[:alert] = ''
    if params[:first_name].to_i == 0 and params[:last_name].to_i == 0
      flash[:alert] += "Please enter your name<br>"
    elsif params[:first_name].to_i == 0
      flash[:alert] += "Please enter your first name<br>"
    elsif params[:last_name].to_i == 0
      flash[:alert] += "Please enter your last name<br>"
    end
    if params[:email] == ''
      flash[:alert] += "Please type in your e-mail address as well<br>"
    elsif not params[:email] =~ /^[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,4}$/
      flash[:alert] += "That doesn't look like a valid e-mail address<br>"
    end  
    if params[:group_id].to_i == 0
      flash[:alert] += "Please choose a group to join<br>"
    elsif params[:group_id].to_i > 0
      @group = Group.find_by_id(params[:group_id])
      if not @group
        flash[:alert] += "Sorry, this group seems to no longer exist<br>"
      elsif @group.openness != 'open'
        flash[:alert] += "Sorry, this group seems to no longer be open to submissions<br>"
      end    
    end 
    if params[:password] == ''
      flash[:alert] += "Please choose a password<br>"
    elsif params[:password_confirmation] == ''
      flash[:alert] += "Please enter your password a second time, to confirm<br>"
    elsif params[:password_confirmation] != params[:password]
      flash[:alert] += "The two passwords don't match<br>"
    end
    @metamaps = Metamap.where(:global_default=>true)
    for metamap in @metamaps
      if params[:meta][metamap.id.to_s].to_i == 0
        flash[:alert] += "Please choose your #{metamap.name}<br>"
      end
    end   
    if flash[:alert] != ''
      redirect_to "/participants/sign_up"
      return
    end  
    
    super
    
    #-- If the record was really created, save group and meta categories

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