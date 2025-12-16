# encoding: utf-8

class ParticipantsController < ApplicationController
  
	layout "admin"
  before_action :authenticate_user_from_token!, :except=>[:create, :visitor_login]
  before_action :authenticate_participant!, :except=>[:create, :visitor_login]
  
  respond_to :html, :xml, :json

  include ActivityPub
  
  def search
    @heading = 'Participants'
    @sort = ['id desc','']
  end
  
  # GET /participants
  # GET /participants.xml
  def index
    @heading = 'Participants'

    participant_id = params[:participant_id].to_i
    first_name = params[:first_name].to_s
    last_name = params[:last_name].to_s
    country_code = params[:country_code].to_s
    status = params[:status].to_s
    sysadmin = params[:sysadmin].to_i

    @per_page = (params[:per_page] || 30).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    sort1 = (params[:sort1] || 'id desc').to_s
    sort2 = params[:sort2].to_s    
    xorder = sort1
    xorder += "," if xorder!="" and sort2!=""
    xorder += sort2 if sort2!=""

    if participant_id>0
      @participants = [Participant.find(participant_id)]
    else  
      @participants = Participant.where(nil)
      @participants = @participants.tagged_with(params[:tags]) if params[:tags].to_s != ''
      @participants = @participants.where(:country_code => country_code) if country_code != '*'
      @participants = @participants.where(:status => status) if status != '*'
      @participants = @participants.where(:first_name => first_name) if first_name != ''
      @participants = @participants.where(:last_name => last_name) if last_name != ''
      @participants = @participants.where(:sysadmin => true) if sysadmin > 0
      @participants = @participants.order(xorder)
      
      @participants = @participants.paginate page: @page, per_page: @per_page
      
      #@participants = Participant.paginate :page=>@page, :per_page => @per_page, :conditions=>"#{xcond}", :order=>xorder
    end
    
    render :partial=>"list", :layout=>false
    
  end  
  

  # GET /participants/1
  # GET /participants/1.xml
  def show
    @heading = 'Participant'
    @participant = Participant.find(params[:id])
    render :partial=>"show", :layout=>false
  end

  # GET /participants/new
  # GET /participants/new.xml
  def new
    @heading = 'New Participant'
    @participant = Participant.new

    render :partial=>"edit", :layout=>false
    #respond_to do |format|
    #  format.html # new.html.erb
    #  format.xml  { render :xml => @participant }
    #end
  end

  # GET /participants/1/edit
  def edit
    @heading = 'Edit Participant'
    @participant = Participant.find(params[:id])
    render :partial=>"edit", :layout=>false
  end

  # POST /participants
  # POST /participants.xml
  def create
    # NB: There's no validation right now, so this will not be called. We'll redirect sign_up to djoin instead
    @participant = Participant.new(participant_params)
    geoupdate

    respond_to do |format|
      if @participant.save
        format.html { rrender :partial=>'show', :layout=>false, :notice => 'Participant was successfully created.' }
        format.xml  { render :xml => @participant, :status => :created, :location => @participant }
      else
        format.html { render :partial => "edit", :layout=>false }
        format.xml  { render :xml => @participant.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /participants/1
  # PUT /participants/1.xml
  def update
    @participant = Participant.find(params[:id])
    #@participant.attributes = params[:participant]
    logger.info("participants#update #{@participant.id}")
    geoupdate

    respond_to do |format|
      if @participant.update_attributes(participant_params)
      #if @participant.save
        format.html { render :partial=>'show', :layout=>false, :notice => 'Participant was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @participant.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /participants/1
  # DELETE /participants/1.xml
  def destroy
    @participant = Participant.find(params[:id])
    @participant.destroy

    respond_to do |format|
      format.html { render plain: "<p>Participant ##{params[:id]} has been deleted</p>" }
      format.xml  { head :ok }
    end
  end
  
  def removedata
    # Remove content and personal data
    # Posts with no replies are removed, others just have their content removed
    @participant = Participant.find(params[:id])
    
    # Use shared deletion method
    stats = delete_participant_data(@participant)
    
    respond_to do |format|
      format.html { render :partial=>'show', :layout=>false, :notice => 'Participant data has been removed' }
    end
  end

  def removepersonal
    # Remove/anonymize personal data, but leave the content in place
    @participant = Participant.find(params[:id])
    p = @participant
    
    picdir = "#{DATADIR}/participants/pictures/#{p.id}"
    `/bin/rm -f #{picdir}/*`
    
    Message.where("from_participant_id=#{p.id} or to_participant_id=#{p.id}").delete_all
        
    # not touching their ratings
    #Rating.where(participant_id: p.id).destroy

    p.first_name = '*'
    p.last_name = '*'
    p.address1 = ''
    p.address2 = ''
    p.city = ''
    p.city_uniq = ''
    p.state_code = ''
    p.state_name = ''
    p.country_code = ''
    p.country_name = ''
    p.zip = ''
    p.phone = ''
    p.county_code = ''
    p.county_name = ''
    p.admin1uniq = ''
    p.fb_uid = ''
    p.fb_link = ''
    p.twitter_username = ''
    p.twitter_oauth_token = ''
    p.visibility = ''
    p.email = "datadeleted#{p.id}@intermix.org"
    p.mycom_email = 'never'
    p.othercom_email = 'never'
    p.private_email = 'never'
    p.system_email = 'never'
    p.no_email = true
    p.old_email = ''
    p.direct_email_code = ''
    p.encrypted_password = "ewrwerwerr345324324#{p.id}"
    p.confirmation_token = "ewrwerwerassdaasd3#{p.id}"
    p.authentication_token = "324533eweder2342423423dssd#{p.id}"
    p.google_uid = ''
    p.account_uniq = ''
    p.account_uniq_full = ''
    p.tag_list = ''
    p.status = 'removed'
    p.save!
    
    remote_followers = Follow.where("followed_id=#{p.id} and following_remote_actor_id is not null")
    for rfollow in remote_followers
      if rfollow.remote_follower
        send_delete_actor(p, rfollow.remote_follower)
      end
    end
    
    Follow.where("following_id=#{p.id} or followed_id=#{p.id}").delete_all
    
    respond_to do |format|
      format.html { render :partial=>'show', :layout=>false, :notice => 'Participant personal data has been removed' }
    end
  end
  
  def visitor_login
    #-- Log in as a visitor
    @participant = Participant.find_by_id(VISITOR_ID)
    sign_in(:participant, @participant)
    redirect_to '/'
  end
  
  protected
  
  def participant_params
    params.require(:participant).permit(
    :picture, :status,
    :first_name, :last_name, :title, :self_description, :address1, :address2, :city, :admin2uniq, :country_code, :country_name, :admin1uniq, :state_code, :state_name, :county_code, :county_name, :zip, :phone,
    :latitude, :longitude, :timezone, :timezone_offset, :metropolitan_area, :metro_area_id, :bioregion, :bioregion_id, :faith_tradition, :faith_tradition_id, :political, :political_id, :email, :visibility,
    :wall_visibility, :item_to_forum, :twitter_post, :twitter_username, :twitter_oauth_token, :twitter_oauth_secret, :forum_email, :group_email, :subgroup_email, :private_email, :system_email, :no_email, :handle,
    :tag_list, :mycom_email, :othercom_email
    )
  end
  
end
