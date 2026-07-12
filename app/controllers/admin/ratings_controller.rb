# encoding: utf-8

class Admin::RatingsController < ApplicationController
  # GET /ratings
  # GET /ratings.xml
  def index
    @from = params[:from]
    @ratings = Rating.where(nil)

    respond_to do |format|
      format.html { render :partial=>'list', :layout=>false }
      format.xml  { render :xml => @ratings }
    end
  end

  # GET /ratings/1
  # GET /ratings/1.xml
  def show
    @from = params[:from]
    @rating = Rating.find(params[:id])

    respond_to do |format|
      format.html { render :partial=>'show', :layout=>false }
      format.xml  { render :xml => @rating }
    end
  end

  # GET /ratings/new
  # GET /ratings/new.xml
  def new
    @from = params[:from]
    @rating = Rating.new(:approval=>0,:interest=>2)
    @rating.participant_id = params[:participant_id]
    @rating.item_id = params[:item_id]
    @rating.group_id = params[:group_id]

    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @rating }
    end
  end

  # GET /ratings/1/edit
  def edit
    @from = params[:from]
    @rating = Rating.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>'edit', :layout=>false }
      format.xml  { render :xml => @rating }
    end
  end

  # POST /ratings
  # POST /ratings.xml
  def create
    @from = params[:from]
    @rating = Rating.new(rating_params)

    respond_to do |format|
      if @rating.save
        format.html { redirect_to(@rating, :notice => 'Rating was successfully created.') }
        format.xml  { render :xml => @rating, :status => :created, :location => @rating }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @rating.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /ratings/1
  # PUT /ratings/1.xml
  def update
    @from = params[:from]
    @rating = Rating.find(params[:id])

    respond_to do |format|
      if @rating.update(rating_params)
        format.html { redirect_to(@rating, :notice => 'Rating was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @rating.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /ratings/1
  # DELETE /ratings/1.xml
  def destroy
    @from = params[:from]
    @rating = Rating.find(params[:id])
    @rating.destroy

    respond_to do |format|
      format.html { redirect_to(ratings_url) }
      format.xml  { head :ok }
    end
  end

  def rating_params
    params.require(:rating).permit(:item_id, :participant_id, :remote_actor_id, :rating_type, :group_id, :dialog_id, :dialog_round_id, :approval, :interest, :importance, :period_id, :conversation_id)
  end
end
