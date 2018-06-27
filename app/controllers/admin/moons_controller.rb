# encoding: utf-8

class Admin::MoonsController < ApplicationController
  
	layout "admin"
  append_before_action :authenticate_participant!

  def search
    @heading = 'Moons'
    @sort = ['id desc','']
  end  
  
  # GET /moons
  # GET /moons.xml
  def index
    moon_id = params[:moon_id].to_i

    @per_page = (params[:per_page] || 30).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    sort1 = (params[:sort1] || 'id desc').to_s
    sort2 = params[:sort2].to_s    
    xorder = sort1
    xorder += "," if xorder!="" and sort2!=""
    xorder += sort2 if sort2!=""

    xcond = "1=1"

    if moon_id>0
      @moons = [Moon.find(moon_id)]
    else  
      @moons = Moon.where(xcond).order(xorder).paginate(:page=>@page, :per_page => @per_page)  
    end
    
    respond_to do |format|
      format.html { render :partial=>'list', :layout=>false }
      format.xml  { render :xml => @moons }
    end
  end

  # GET /moons/1
  # GET /moons/1.xml
  def show
    @moon = Moon.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'show', :layout=>false }
      format.xml  { render :xml => @moon }
    end
  end

  # GET /moons/new
  # GET /moons/new.xml
  def new
    mtype = params[:mtype]
    @moon = Moon.new
    @moon.new_or_full = mtype
    if mtype == 'new'
      @moon.top_text = "Each new moon, the highest rated Voices of Humanity messages for the month are emailed to all active VoH subscribers. The Voice of Humanity-as-One is the overall highest rated message for the month. The Voice of Women is the highest rated message written by a woman and as rated by the women and similarly for the other Voices."
      @moon.topic = "Something Unexpected"
    elsif mtype == 'full'      
      @moon.top_text = "Each full moon, the highest rated nonviolent action oriented Voices of Humanity messages for the month are emailed to all active VoH subscribers. The Voice of Humanity-as-One is the overall highest rated action message for the month. The Voice of Women is the highest rated action message written by a woman and as rated by the women and similarly for the other Voices."
      @moon.topic = "Nonviolent Action for Human Unity"
    end
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @moon }
    end
  end

  # GET /moons/1/edit
  def edit
    @moon = Moon.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @moon }
    end
  end

  # POST /moons
  # POST /moons.xml
  def create
    @moon = Moon.new(params[:moon])

    respond_to do |format|
      if @moon.save
        format.html { render :partial=>'show', :layout=>false, :notice => 'Moon was successfully created.' }
        format.xml  { render :xml => @moon, :status => :created, :location => @moon }
      else
        format.html { render :partial=>'edit', :layout=>false }
        format.xml  { render :xml => @moon.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /moons/1
  # PUT /moons/1.xml
  def update
    @moon = Moon.find(params[:id])

    respond_to do |format|
      if @moon.update_attributes(params[:moon])
        format.html { render :partial=>'show', :layout=>false, :notice => 'Group was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :partial => "edit", :layout=>false }
        format.xml  { render :xml => @moon.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /moons/1
  # DELETE /moons/1.xml
  def destroy
    @moon = Moon.find(params[:id])
    @moon.destroy

    respond_to do |format|
      format.html { render plain: "<p>Moon ##{params[:id]} has been deleted</p>" }
      format.xml  { head :ok }
    end
  end
  
  def admins
    #-- Return a list of the admins for this moon
    @moon_id = params[:id].to_i

    @moon = Moon.includes(:participants).find(@moon_id)
    
    @participants = Participant.where(nil)
    
    render :partial=>"admins", :layout=>false
  end  
  
  def admin_add
    #-- Add a moon admin
    @moon_id = params[:id].to_i
    @participant_id = params[:participant_id]
    moon_admin = MoonAdmin.where(["moon_id = ? and participant_id = ?", @moon_id, @participant_id]).first
    if not moon_admin
      moon_admin = MoonAdmin.create(:moon_id => @moon_id, :participant_id => @participant_id)
    end
    admins    
  end 
  
  def admin_del 
    #-- Delete a moon admin
    @moon_id = params[:id].to_i
    participant_ids = params[:participant_ids]
    for participant_id in participant_ids
      moon_admin = MoonAdmin.where(["moon_id = ? and participant_id = ?", @moon_id, participant_id]).first
      if moon_admin
        moon_admin.destroy
      end
    end
    admins
  end
  
end
