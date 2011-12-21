# encoding: utf-8

class ForumController < ApplicationController
 
  layout "front"
  before_filter :authenticate_participant!
  
  def index
    #-- Show most recent items that this user is allowed to see
    @section = 'forum'
    @from = 'forum'
    
    if participant_signed_in? and current_participant.forum_settings
      set = current_participant.forum_settings
    else
      set = {}
    end    
    @sortby = params[:sortby] || set['sortby'] || "items.id desc"
    @perscr = (params[:perscr] || set['perscr'] || 25).to_i
    @page = ( params[:page] || 1 ).to_i
    @page = 1 if @page < 1
    @threads = params[:threads] || set['threads'] || ''
    @group_id = (params[:group_id] || set['group_id'] || 0).to_i
    @dialog_id = (params[:dialog_id] || set['dialog_id'] || 0).to_i

    if @sortby[0,5] == 'meta:'
       @sortby = 'items.id desc'
    end

    @items = Item.scoped
    @items = @items.where(:posted_to_forum => true)  
    if @group_id > 0
      @items = @items.where("items.group_id = ?", @group_id)    
    end
    if @dialog_id > 0
      @items = @items.where("items.dialog_id = ?", @dialog_id)    
    end
    if @threads == 'flat' or @threads == 'tree'
      #- Show original message followed by all replies in a flat list
      @items = @items.where("is_first_in_thread=1")
    end
    #@items = @items.tagged_with(params[:tags]) if params[:tags].to_s != ''
    #@items = @items.where(:group_id => params[:group_id]) if params[:group_id].to_i > 0
    #@items = @items.includes([:group,:participant,:ratings,:item_rating_summary]).where("ratings.participant_id=#{current_participant.id} or ratings.participant_id is null")
    @items = @items.includes([:group,:participant,:item_rating_summary])
    @items = @items.joins("left join ratings on (ratings.item_id=items.id and ratings.participant_id=#{current_participant.id})")
    @items = @items.select("items.*,ratings.participant_id as hasrating,ratings.approval,ratings.interest")
    
    @items = @items.order(@sortby)
    @items = @items.paginate :page=>@page, :per_page => @per_page    
    @groupsin = GroupParticipant.where("participant_id=#{current_participant.id}").includes(:group).all      
    @dialogsin = DialogParticipant.where("participant_id=#{current_participant.id}").includes(:dialog).all      
    @dialogs = Dialog.all      
    update_last_url
  end  
  
  
end
