# encoding: utf-8

class Admin::AdminController < ApplicationController

	layout "admin"
  before_filter :authenticate_participant!, :is_sysadmin
  
  def index
    @heading = 'Administration'
  end
    
end
