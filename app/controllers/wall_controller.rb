require 'will_paginate/array'

class WallController < ApplicationController

  layout "front"
  before_action :authenticate_user_from_token!
  before_action :authenticate_participant!

  def index
    #-- show somebody's wall, or the member's wall
    @section = 'wall'
    @psection = 'wall'
    @from = 'wall'
    @participant_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.find(@participant_id)
    @sortby = params[:sortby] || "items.id desc"
    @perscr = params[:perscr].to_i || 10
    @page = params[:page].to_i
    @page = 1 if @page <= 0
    
    #@items = Item.scoped
    #@items = @items.where(:posted_by => @participant_id)
    #@items = @items.includes([:group,:item_rating_summary])
    #@items = @items.joins("left join ratings on (ratings.item_id=items.id and ratings.participant_id=#{current_participant.id})")
    #@items = @items.select("items.*,ratings.participant_id as hasrating,ratings.approval as rateapproval,ratings.interest as rateinterest,'' as explanation")
    #@items = @items.order(@sortby)
    #@items = @items.paginate :page=>@page, :per_page => @per_page    
    
    
    #@items, @itemsproc = Item.list_and_results(nil,nil,nil,@participant_id,{},{},false,'items.id desc',current_participant.id)
    
    
    crit = {}
    crit[:posted_by] = @participant_id
    rootonly = false
    
    items,ratings,@title = Item.get_items(crit,current_participant,rootonly)
    @itemsproc,@extras = Item.get_itemsproc(items,ratings,current_participant.id,rootonly)
    @items = Item.get_sorted(items,@itemsproc,@sortby,rootonly)
       
    @items = @items.paginate page: @page, per_page: 10  
       
    update_last_url
  end  


end
