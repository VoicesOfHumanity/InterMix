class MoonsController < ApplicationController
  before_action :set_moon, only: [:show, :edit, :update, :destroy]

  # GET /moons
  def index
    @moons = Moon.all
  end

  # GET /moons/1
  def show
  end

  # GET /moons/new
  def new
    @moon = Moon.new
  end

  # GET /moons/1/edit
  def edit
  end

  # POST /moons
  def create
    @moon = Moon.new(moon_params)

    if @moon.save
      redirect_to @moon, notice: 'Moon was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /moons/1
  def update
    if @moon.update(moon_params)
      redirect_to @moon, notice: 'Moon was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /moons/1
  def destroy
    @moon.destroy
    redirect_to moons_url, notice: 'Moon was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_moon
      @moon = Moon.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def moon_params
      params.require(:moon).permit(:mdate, :top_text)
    end
end
