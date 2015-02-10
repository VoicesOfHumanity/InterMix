# encoding: utf-8

class Admin::DialogsController < ApplicationController

	layout "admin"
  before_filter :authenticate_participant!

  def search
    @heading = 'Dialogs'
    @sort = ['id desc','']
  end  
  
  # GET /dialogs
  # GET /dialogs.xml
  def index
    dialog_id = params[:dialog_id].to_i

    @per_page = (params[:per_page] || 30).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    sort1 = (params[:sort1] || 'id desc').to_s
    sort2 = params[:sort2].to_s    
    xorder = sort1
    xorder += "," if xorder!="" and sort2!=""
    xorder += sort2 if sort2!=""

    xcond = "1=1"

    if dialog_id>0
      @dialogs = [Dialog.find(group_id)]
    else  
      @dialogs = Dialog.where(xcond).order(xorder).includes(:creator,:maingroup).paginate(:page=>@page, :per_page => @per_page)    
    end
    
    respond_to do |format|
      format.html { render :partial=>'list', :layout=>false }
      format.xml  { render :xml => @dialogs }
    end
  end

  # GET /dialogs/1
  # GET /dialogs/1.xml
  def show
    @dialog = Dialog.includes(:creator,:maingroup).find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'show', :layout=>false }
      format.xml  { render :xml => @dialog }
    end
  end

  # GET /dialogs/new
  # GET /dialogs/new.xml
  def new
    @dialog = Dialog.new
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @dialog }
    end
  end

  # GET /dialogs/1/edit
  def edit
    @dialog = Dialog.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @dialog }
    end
  end

  # POST /dialogs
  # POST /dialogs.xml
  def create
    @dialog = Dialog.new(params[:dialog])
    @dialog.created_by = current_participant.id

    respond_to do |format|
      if @dialog.save
        format.html { render :partial=>'show', :layout=>false, :notice => 'Dialog was successfully created.' }
        format.xml  { render :xml => @dialog, :status => :created, :location => @dialog }
      else
        format.html { render :partial=>'edit', :layout=>false }
        format.xml  { render :xml => @dialog.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /dialogs/1
  # PUT /dialogs/1.xml
  def update
    @dialog = Dialog.find(params[:id])
    @dialog.created_by = current_participant.id if not @dialog.created_by

    respond_to do |format|
      if @dialog.update_attributes(params[:dialog])
        format.html { render :partial=>'show', :layout=>false, :notice => 'Group was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :partial => "edit", :layout=>false }
        format.xml  { render :xml => @dialog.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /dialogs/1
  # DELETE /dialogs/1.xml
  def destroy
    @dialog = Dialog.find(params[:id])
    @dialog.destroy

    respond_to do |format|
      format.html { render :text=>"<p>Dialog ##{params[:id]} has been deleted</p>" }
      format.xml  { head :ok }
    end
  end
  
  def admins
    #-- Return a list of the admins for this dialog
    @dialog_id = params[:id].to_i

    @dialog = Dialog.includes(:dialog_admins).find(@dialog_id)
    
    @participants = Participant.where(nil)
    
    render :partial=>"admins", :layout=>false
  end  
  
  def admin_add
    #-- Add a dialog admin
    @dialog_id = params[:id].to_i
    @participant_id = params[:participant_id]
    dialog_admin = DialogAdmin.where(["dialog_id = ? and participant_id = ?", @dialog_id, @participant_id]).first
    if not dialog_admin
      dialog_admin = DialogAdmin.create(:dialog_id => @dialog_id, :participant_id => @participant_id)
    end
    admins    
  end 
  
  def admin_del 
    #-- Delete a dialog admin
    @dialog_id = params[:id].to_i
    participant_ids = params[:participant_ids]
    for participant_id in participant_ids
      dialog_admin = DialogAdmin.where(["dialog_id = ? and participant_id = ?", @dialog_id, participant_id]).first
      if dialog_admin
        dialog_admin.destroy
      end
    end
    admins
  end

  def groups
    #-- Return a list of the groups in this dialog
    @dialog_id = params[:id].to_i

    @dialog = Dialog.includes(:groups).find(@dialog_id)
    
    @groups = Group.where(nil)
    
    render :partial=>"groups", :layout=>false
  end  
  
  def group_add
    #-- Add a group to the dialog
    @dialog_id = params[:id].to_i
    @group_id = params[:group_id]
    dialog_group = DialogGroup.where(["dialog_id = ? and group_id = ?", @dialog_id, @group_id]).first
    if not dialog_group
      dialog_group = DialogGroup.create(:dialog_id => @dialog_id, :group_id => @group_id)
    end
    groups    
  end 
  
  def group_del 
    #-- Delete a group from the dialog
    @dialog_id = params[:id].to_i
    group_ids = params[:group_ids]
    for group_id in group_ids
      dialog_group = DialogGroup.where(["dialog_id = ? and group_id = ?", @dialog_id, group_id]).first
      if dialog_group
        dialog_group.destroy
      end
    end
    groups
  end
  
end
