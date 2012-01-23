class WallController < ApplicationController

  layout "front"
  before_filter :authenticate_participant!

  def index
    #-- show somebody's wall, or the member's wall
    @section = 'wall'
    @from = 'wall'
    @participant_id = ( params[:id] || current_participant.id ).to_i
    @participant = Participant.find(@participant_id)
    @sortby = params[:sortby] || "items.id desc"
    @perscr = params[:perscr].to_i || 25
    @items = Item.scoped
    @items = @items.where(:posted_by => @participant_id)
    @items = @items.includes([:group,:item_rating_summary])
    @items = @items.joins("left join ratings on (ratings.item_id=items.id and ratings.participant_id=#{current_participant.id})")
    @items = @items.order(@sortby)
    @items = @items.paginate :page=>@page, :per_page => @per_page    
    if env['warden'].session[:dialog_id].to_i > 0
      @dialog = Dialog.find_by_id(env['warden'].session[:dialog_id])
    end
    update_last_url
  end  


end
