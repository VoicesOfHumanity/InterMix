# encoding: utf-8

class ParticipantsController < ApplicationController
  
	layout "admin"
  before_filter :authenticate_user_from_token!, :except=>:create
  before_filter :authenticate_participant!, :except=>:create
  respond_to :html, :xml, :json
  
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
      
      @participants = @participants.paginate :page=>@page, :per_page => @per_page    
      
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
      format.html { render :text=>"<p>Participant ##{params[:id]} has been deleted</p>" }
      format.xml  { head :ok }
    end
  end
  
  protected
  
  def geoupdate
    #-- Update geo-related fields, when saving a participant, or if one of the fields changed
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
  
  def participant_params
    params.require(:participant).permit(
    :picture,
    :first_name, :last_name, :title, :self_description, :address1, :address2, :city, :admin2uniq, :country_code, :country_name, :admin1uniq, :state_code, :state_name, :county_code, :county_name, :zip, :phone,
    :latitude, :longitude, :timezone, :timezone_offset, :metropolitan_area, :metro_area_id, :bioregion, :bioregion_id, :faith_tradition, :faith_tradition_id, :political, :political_id, :email, :visibility,
    :wall_visibility, :item_to_forum, :twitter_post, :twitter_username, :twitter_oauth_token, :twitter_oauth_secret, :forum_email, :group_email, :subgroup_email, :private_email, :system_email, :no_email, :handle
    )
  end
  
end
