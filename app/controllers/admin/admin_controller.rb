# encoding: utf-8

class Admin::AdminController < ApplicationController

	layout "admin"
  before_filter :authenticate_participant!
  
  def index
    @heading = 'Administration'
  end
    
end
