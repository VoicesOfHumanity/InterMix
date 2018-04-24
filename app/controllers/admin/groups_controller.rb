# encoding: utf-8

class Admin::GroupsController < ApplicationController
  
	layout "admin"
  append_before_action :authenticate_participant!
  
  def search
    @heading = 'Groups'
    @sort = ['id desc','']
  end  
  
  # GET /groups
  # GET /groups.xml
  def index

    group_id = params[:group_id].to_i

    @per_page = (params[:per_page] || 30).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    sort1 = (params[:sort1] || 'id desc').to_s
    sort2 = params[:sort2].to_s    
    xorder = sort1
    xorder += "," if xorder!="" and sort2!=""
    xorder += sort2 if sort2!=""

    xcond = "1=1"

    if group_id>0
      @groups = [Group.find(group_id)]
    else  
      @groups = Group.where(xcond).order(xorder).paginate(:page=>@page, :per_page => @per_page)    
    end
    
    respond_to do |format|
      format.html { render :partial=>'list', :layout=>false }
      format.xml  { render :xml => @groups }
    end

  end

  # GET /groups/1
  # GET /groups/1.xml
  def show
    @group = Group.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'show', :layout=>false }
      format.xml  { render :xml => @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.xml
  def new
    @group = Group.new
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @group }
    end
  end

  # GET /groups/1/edit
  def edit
    @group = Group.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @group }
    end
  end

  # POST /groups
  # POST /groups.xml
  def create
    @group = Group.new(group_params)

    respond_to do |format|
      if @group.save
        format.html { render :partial=>'show', :layout=>false, :notice => 'Group was successfully created.' }
        format.xml  { render :xml => @group, :status => :created, :location => @group }
      else
        format.html { render :partial => "edit", :layout=>false }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    @group = Group.find(params[:id])
    logger.info("groups#update #{@group.id}")

    respond_to do |format|
      if @group.update_attributes(group_params)
        format.html { render :partial=>'show', :layout=>false, :notice => 'Group was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :partial => "edit", :layout=>false }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    @group = Group.find(params[:id])
    @group.destroy

    respond_to do |format|
      format.html { render plain: "<p>Group ##{params[:id]} has been deleted</p>" }
      format.xml  { head :ok }
    end
  end
  
  def member_list
    group_id = params[:group_id]
    #@group_participants = Group.where(:group_id=>group_id).includes(:participants).order("participant.last_name,participant.first_name").select("participants.*")    
    @group_participants = GroupParticipant.where("group_id=#{group_id}").order("created_at desc").includes(:participant)
    respond_to do |format|
      format.html { render :partial=>"member_list", :layout=>false }
      format.xml  { render :xml => @group_members }
    end   
  end  
 
  def dialogs
    #-- Return a list of the dialogs this group is a member of
    @group_id = params[:id].to_i

    @group = Group.includes(:dialogs).find(@group_id)
    
    @dialogs = Dialog.where(nil)
    
    render :partial=>"dialogs", :layout=>false
  end  
 
  protected
  
  def group_params
    params.require(:group).permit(:is_global, :logo, :name, :shortname, :description, :shortdesc, :instructions, :visibility, :message_visibility, :openness, :moderation, :twitter_post, :twitter_username, :twitter_oauth_token, :twitter_oauth_secret, :twitter_hash_tag, :has_mail_list, :front_template, :member_template, :invite_template, :import_template, :signup_template, :confirm_template, :confirm_email_template, :confirm_welcome_template, :alt_logins, :required_meta, :tweet_approval_min, :tweet_what, :tweet_subgroups, :is_network)
  end
  
end
