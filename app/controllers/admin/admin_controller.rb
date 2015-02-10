# encoding: utf-8

class Admin::AdminController < ApplicationController

	layout "admin"
  append_before_action :authenticate_participant!, :is_sysadmin
  
  def index
    @heading = 'Administration'
  end
    
end
