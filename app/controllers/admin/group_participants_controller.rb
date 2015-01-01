# encoding: utf-8

class Admin::GroupParticipantsController < ApplicationController
  
	layout "admin"
  before_filter :authenticate_participant!
  
  def index
    @from = params[:from] || ''
    @group_id = params[:group_id].to_i
    @participant_id = params[:participant_id].to_i
    @order = params[:order] || "id desc"
    @moderator = (params[:moderator].to_s == 'true')
    #@group_participants = GroupParticipant.where("group_id=#{@group_id}").order("created_at desc").includes(:participant)
    
    # NB: how to get the base, without having to put order first?
    @group_participants = GroupParticipant.order(@order).includes(:participant)
    @group_participants =  @group_participants.where("group_id=#{@group_id}") if @group_id > 0
    @group_participants =  @group_participants.where("participant_id=#{@participant_id}") if @participant_id > 0
    @group_participants =  @group_participants.where("moderator=1") if @moderator
    @group_participants.where(nil)
    
    respond_to do |format|
      format.html { render :partial=>"list", :layout=>false }
      format.xml  { render :xml => @group_participants }
    end   
  end  
  
  def show
    @from = params[:from] || ''
    @group_participant = GroupParticipant.find(params[:id],:include=>[:participant,:group])
    respond_to do |format|
      format.html { render :partial=>'show', :layout=>false }
      format.xml  { render :xml => @group_participant }
    end
  end
  
  def new
    @from = params[:from] || ''
    @group_participant = GroupParticipant.new(:moderator => false, :active => true)
    @group_participant.active = true
    @group_participant.group_id = params[:group_id]
    @group_participant.participant_id = params[:participant_id]
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @group_participant }
    end
  end

  def edit
    @from = params[:from] || ''
    @group_participant = GroupParticipant.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @group_participant }
    end
  end

  def create
    @from = params[:from] || ''
    @group_participant = GroupParticipant.new(params[:group_participant])

    respond_to do |format|
      if @group_participant.save
        format.html { render :partial=>'show', :layout=>false, :notice => 'Group membership was successfully created.' }
        format.xml  { render :xml => @group_participant, :status => :created, :location => @group_participant }
      else
        format.html { render :partial=>'edit', :layout=>false }
        format.xml  { render :xml => @group_participant.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @from = params[:from] || ''
    @group_participant = GroupParticipant.find(params[:id])

    respond_to do |format|
      if @group_participant.update_attributes(params[:group_participant])
        format.html { render :partial=>'show', :layout=>false, :notice => 'Group membership was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :partial => "edit", :layout=>false }
        format.xml  { render :xml => @group_participant.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @from = params[:from] || ''
    @group_participant = GroupParticipant.find(params[:id])
    @group_participant.destroy

    respond_to do |format|
      format.html { render :text=>"<p>Participant has been removed from group</p>" }
      format.xml  { head :ok }
    end
  end
  
  
end
