class Admin::HelpTextsController < ApplicationController
  
  Admin::HelpTextsController < ApplicationController

  	layout "admin"
    before_filter :authenticate_participant!

    def search
      @heading = 'Help Texts'
      @sort = ['id desc','']
    end  

    # GET /help_texts
    # GET /help_texts.xml
    def index
      help_text_id = params[:help_text_id].to_i
      code = params[:code].to_s
      description = params[:description].to_s

      @per_page = (params[:per_page] || 30).to_i
      @page = ( params[:page] || 1 ).to_i
      @page = 1 if @page < 1
      sort1 = (params[:sort1] || 'id desc').to_s
      sort2 = params[:sort2].to_s    
      xorder = sort1
      xorder += "," if xorder!="" and sort2!=""
      xorder += sort2 if sort2!=""

      xcond = "1=1"

      if help_text_id > 0
        @help_texts = [HelpText.find(help_text_id)]
      else  
        xcond += " and code='#{code}'" if code != ''
        xcond += " and description like '#{description}'" if description != ''
        
        @help_texts = HelpText.paginate :page=>@page, :per_page => @per_page, :conditions=>"#{xcond}", :order=>xorder    
      end

      respond_to do |format|
        format.html { render :partial=>'list', :layout=>false }
        format.xml  { render :xml => @help_texts }
      end
    end

    # GET /help_texts/1
    # GET /help_texts/1.xml
    def show
      @help_text = HelpText.find(params[:id])
      respond_to do |format|
        format.html { render :partial=>'show', :layout=>false }
        format.xml  { render :xml => @help_text }
      end
    end

    # GET /help_texts/new
    # GET /help_texts/new.xml
    def new
      @help_text = HelpText.new
      respond_to do |format|
        format.html { render :partial=>'edit', :layout=>false }
        format.xml  { render :xml => @help_text }
      end
    end

    # GET /help_texts/1/edit
    def edit
      @help_text = HelpText.find(params[:id])
      respond_to do |format|
        format.html { render :partial=>'edit', :layout=>false }
        format.xml  { render :xml => @help_text }
      end
    end

    # POST /help_texts
    # POST /help_texts.xml
    def create
      @help_text = HelpText.new(params[:help_text])

      respond_to do |format|
        if @help_text.save
          format.html { render :partial=>'show', :layout=>false, :notice => 'Hub was successfully created.' }
          format.xml  { render :xml => @help_text, :status => :created, :location => @help_text }
        else
          format.html { render :partial=>'edit', :layout=>false }
          format.xml  { render :xml => @help_text.errors, :status => :unprocessable_entity }
        end
      end
    end

    # PUT /help_texts/1
    # PUT /help_texts/1.xml
    def update
      @help_text = HelpText.find(params[:id])

      respond_to do |format|
        if @help_text.update_attributes(params[:help_text])
          format.html { render :partial=>'show', :layout=>false, :notice => 'Group was successfully updated.' }
          format.xml  { head :ok }
        else
          format.html { render :partial => "edit", :layout=>false }
          format.xml  { render :xml => @help_text.errors, :status => :unprocessable_entity }
        end
      end
    end

    # DELETE /help_texts/1
    # DELETE /help_texts/1.xml
    def destroy
      @help_text = HelpText.find(params[:id])
      @help_text.destroy

      respond_to do |format|
        format.html { render :text=>"<p>Hub ##{params[:id]} has been deleted</p>" }
        format.xml  { head :ok }
      end
    end

  
end
