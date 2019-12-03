class Item < ActiveRecord::Base
  belongs_to :participant, :counter_cache => true, :foreign_key => :posted_by
  belongs_to :moderatedparticipant, :class_name => "Participant", :foreign_key => :moderated_by
  belongs_to :group, :counter_cache => true
  belongs_to :dialog
  belongs_to :period
  has_many :allratings, :class_name=>"Rating"
  has_one :item_rating_summary
  
  has_many :item_subscribes
  has_many :subscribers, class_name: "Participant", :through => :item_subscribes
    
  serialize :oembed_response
  
  #-- We store the result of the voting_ok check in attributes. Is it ok? Explanation? For what user?
  attr_accessor :v_ok, :v_ok_exp, :v_p_id
  
  acts_as_taggable
  acts_as_taggable_on :subgroups
  
  after_create :process_new_item
  
  validates :item_type, :presence => true, :inclusion => { :in => ITEM_TYPES }
  validates :media_type, :presence => true, :inclusion => { :in => MEDIA_TYPES }
  validates :posted_by, :presence => { :message => "Poster missing" }
  
  def self.tags
    tag_counts.collect {|t| t.name}.join(', ')  
  end
  
  def tag_list_downcase
    tag_list.map(&:downcase)
  end
  
  def excerpt
    #-- A 35 word excerpt, to use as an alternative to the tweet version
    plain_content = ActionView::Base.full_sanitizer.sanitize(self.html_content.to_s).strip
    # plain_content.scan(/(\w|-)+/).size    
    plain_content.split[0...35].join(' ')
    #ApplicationController.helpers.my_helper_method
  end
  
  def self.thumbs(iproc)
    #-- Return one of -3, -2, -1, 0, 1, 2, 3, depending on number of thumbs
    #logger.info("Item#thumbs #{iproc ? 'has iproc' : 'no iproc!'}")
    #logger.info("Item#thumbs hasrating:#{iproc['hasrating'] ? iproc['hasrating'] : no}")
    
    #-- approval is between -3 and +3 already, so that will be the thumbs, if we have nothing else
    if iproc and iproc['hasrating'].to_i > 0 and iproc['rateapproval']
      approval = iproc['rateapproval'].to_i
    else
      approval = 0
    end
    #logger.info("Item#thumbs approval:#{approval}")
    numthumbs = approval
    
    #if numthumbs == 0
    #  #-- Use interest as positive thumbs, if we don't have anything already
    #  if iproc and iproc['hasrating'].to_i > 0 and iproc['rateinterest']
    #    interest = iproc['rateinterest'].to_i
    #  else
    #    interest = 0
    #  end
    #  numthumbs = interest
    #  if numthumbs > 3
    #    numthumbs = 3
    #  end
    #end

    # Look at comments 

    return numthumbs
  end
  
  def has_voted(p)
    #-- Has that user already voted on this item?
    rating = Rating.where(item_id: self.id, participant_id: p.id).first
    if rating
      return true
    else
      return false
    end
  end
  
  def is_followed_by(p,returns='bool')
    #-- Is that user already being emailed this item, or already has chosen to follow it
    if self.is_first_in_thread
      top = self
    else
      top = Item.find_by_id(self.first_in_thread) 
    end
    if top
      item = top
    else
      item = self
      top = self
    end
    
    followed = false
    exp = "root:#{top.id if top}, "
    
    
    item_subscribe = ItemSubscribe.where(item_id: top.id, participant_id: p.id).first
    if item_subscribe
      # If there's a specific follow record, that overrides anything else
      followed = item_subscribe.followed
      if followed
        exp += "following because of a direct subscription"        
      else
        exp += "not following because of a direct unsubscription"
      end
      
    elsif top.posted_by.to_i == p.id  
      # is this the author of the root?
      followed = true
      exp += "following because you're author of root"
      
    else    
      # See what the default behavior is
    
      # To find if they would get it as a default, check the community match and their settings

      # Does the user have any tags found in the message tags for that message?
      hasmessmatch = ( p.tag_list.class == ActsAsTaggableOn::TagList and p.tag_list_downcase.length > 0 and p.tag_list_downcase.any?{|t| self.tag_list_downcase.include?(t) } )
    
      # Does the user have any tags found in the community tags of the author of that message
      hascommatch = ( p.tag_list.class == ActsAsTaggableOn::TagList and p.tag_list_downcase.length > 0 and p.tag_list_downcase.any?{|t| self.participant and self.participant.tag_list_downcase.include?(t) } )
    
      is_mycom = (hasmessmatch and hascommatch)

      if is_mycom and (p.mycom_email != 'never')
        followed = true
        exp += "following because it's in your communities and your setting for that is #{p.mycom_email}"
        
      elsif not is_mycom and (p.othercom_email != 'never')
        
        if self.intra_com.to_s != '' and self.intra_com != 'public'
          followed = false
          exp += "not following because it is for #{self.intra_com} only and you're not in it"          
        else  
          followed = true
          exp += "following because it's not in your communities and your setting for that is #{p.othercom_email}"
        end

      elsif is_mycom
        followed = false
        exp += "not following, even though in your communities, because setting is never"
        
      elsif not is_mycom
        followed = false
        exp += "not following, not in your communities, set for never"

      end   

    end
      
    if returns == 'exp'
      return exp
    else  
      return followed
    end
  end
  
  def add_image(tempfilepath)
    #-- Handle an image that has been uploaded
    @picdir = "#{DATADIR}/items/#{self.id}"
    `mkdir "#{@picdir}"` if not File.exist?(@picdir)
    @bigfilepath = "#{@picdir}/big.jpg"
    @thumbfilepath = "#{@picdir}/thumb.jpg"

    iwidth = iheight = 0
    begin
      iwidth,iheight = ImageSize.path(tempfilepath).size
    rescue
      logger.info("item#add_image couldn't get size of #{tempfilepath}")
      iwidth = iheight = 0
    end
    
    p = Magick::Image.read("#{tempfilepath}").first
    if p
      p.auto_orient!
      iwidth = p.columns
      iheight = p.rows
      if iwidth > 640 or iheight > 640
        p.change_geometry('640x640') { |cols, rows, img| img.resize!(cols, rows) }
      end
      p.write("#{@bigfilepath}")
    end
    
    logger.info("item#add_image converting #{tempfilepath} (#{iwidth}x#{iheight}) to #{@bigfilepath}")         

    if p and File.exist?(@bigfilepath)

  		bigpicsize = File.stat("#{@bigfilepath}").size
      iwidth = iheight = 0
      begin
        iwidth,iheight = ImageSize.path(@bigfilepath).size
      rescue
        logger.info("item#add_image couldn't get size of #{@bigfilepath}")
        iwidth = iheight = 0
      end  
      logger.info("item#add_image size:#{bigpicsize} dim:#{iwidth}x#{iheight}")
    
      #-- Construct an icon image 100x100
      #`rm -f #{tempfilepath2}` if File.exist?(tempfilepath2)
    
      if iwidth >= iheight
        p.change_geometry('1000x100') { |cols, rows, img| img.resize!(cols, rows) }
      else
        p.change_geometry('100x1000') { |cols, rows, img| img.resize!(cols, rows) }
      end
      #p.write("#{tempfilepath2}")

      #if File.exist?(tempfilepath2)
        #p = Magick::Image.read("#{tempfilepath}").first
        if iwidth >= iheight
          #-- If it is a landscape picture, get the middle part
          width = iwidth * 100 / iheight
          offset = ((width - 100) / 2).to_i
          icon = p.crop(offset, 0, 100, 100)
        else
          #-- If it is a portrait picture, get the top part
          icon = p.crop(0, 0, 100, 100)
        end
        icon.write("#{@thumbfilepath}")
      #end
    
      p.destroy! if p
      icon.destroy! if icon
      
      self.has_picture = true
    
    end
  end  
  
  def process_new_item
    #-- Do stuff that needs to be done to process and distrubte a new item
    #-- E-mail it to everybody who needs to get it in e-mail
    #-- Post it to twitter
    logger.info("Item#process_new_item")
    create_xml
    if old_message_id.to_i == 0
      #-- Only twitter and e-mail if it really is a new message just being posted
      personal_twitter
      emailit
    end
    self.save
  end  
  
  def best_image
    #-- Return the best image to represent an item, for example for facebook
    #-- That will either be the picture that goes with the item, or a site logo
    if File.exist?("#{DATADIR}/items/#{self.id}/thumb.jpg")
      return "/images/data/items/#{self.id}/thumb.jpg"
    else
      return VOL_LOGO
    end
  end


  def emailit
    #-- E-mail this item to everybody who's configured to receive it
    #-- This might be either people who has an author tag found within this message's message or author tags 
    #-- and who has My Communities set to instant
    #-- or it might be people who don't have any matching tags, but who have Other Communities set to instant
    #-- Each person might be configured to receive e-mails or not 
    #-- It all gets overridden by their follow settings

    participants = []   
    got_participants = {}
        
    # mycom: will go to people who share any community with the author and who has any community tag matching a message tag
    
    allpeople = Participant.where(status: 'active').where("mycom_email='instant' or othercom_email='instant'")
    for person in allpeople
      hasmessmatch = ( person.tag_list.class == ActsAsTaggableOn::TagList and person.tag_list_downcase.length > 0 and person.tag_list_downcase.any?{|t| self.tag_list_downcase.include?(t) } )
      hascommatch = ( person.tag_list.class == ActsAsTaggableOn::TagList and person.tag_list_downcase.length > 0 and person.tag_list_downcase.any?{|t| self.participant.tag_list_downcase.include?(t) } )
      if person.id == 6 or person.id == 1867
        logger.info("Item#emailit person #{person.id}: hasmessmatch:#{hasmessmatch} with item #{self.id}")
        logger.info("Item#emailit person #{person.id}: hascommatch:#{hascommatch} with person #{self.participant.id}")
      end
      person.explanation = "hasmessmatch:#{hasmessmatch} with item #{self.id}. hascommatch:#{hascommatch} with person #{self.participant.id}. "
      if hasmessmatch and hascommatch and person.mycom_email == 'instant'
        person.explanation += "Match, and person.mycom_email is instant. "
        participants << person
        got_participants[person.id] = true
      elsif not (hasmessmatch and hascommatch) and person.othercom_email == 'instant'
        person.explanation += "Mismatch, and person.othercom_email is instant. "
        participants << person
        got_participants[person.id] = true
      end      
    end
    logger.info("Item#emailit #{participants.length} recipients based on community settings")
    
    if self.is_first_in_thread
      top = self
    else
      top = Item.find_by_id(self.first_in_thread) 
    end
    
    if self.intra_com == 'public'
    elsif self.intra_com.to_s != ''
      # It is for a particular community only. Remove anybody who's not a member
      tagname = self.intra_com[1,50]
      for person in allpeople
        if not person.tag_list_downcase.include?(tagname.downcase)
          participants.delete(person)
        end
      end  
    end    

    # Root author should get anything in the thread, so make sure they're on the list
    if top and top.posted_by.to_i > 0 and not got_participants.has_key?(top.posted_by.to_i)
      author = Participant.find_by_id(top.posted_by)
      if author
        author.explanation = "This is the thread author. "
        participants << author
        got_participants[author.id] = true
      end
    end
    
    # Check this against people who specifically follow or unfollow it
    followers = top.subscribers
    logger.info("Item#emailit checking #{followers.length} subscribers/unsubscribers")
    for person in followers
      xfollow = top.is_followed_by(person)
      logger.info("Item#emailit user #{person.id} follows: #{xfollow}")
      if xfollow and not got_participants.has_key?(person.id)
        person.explanation += "Specifically follows this thread. "
        participants << person
        got_participants[person.id] = true
        logger.info("Item#emailit user #{person.id} specifically follows #{top.id}. Added to mailing.")
      elsif not xfollow and got_participants.has_key?(person.id)
        participants.delete(person)
        got_participants.except!(person.id)
        logger.info("Item#emailit user #{person.id} specifically unfollows #{top.id}. Removed from mailing.")
      end
    end
          
    logger.info("Item#emailit #{participants.length} people to distribute to")
    
    if self.dialog_id.to_i > 0
      dialog = Dialog.find_by_id(self.dialog_id)
    end
    if self.period_id.to_i > 0
      period = Period.find_by_id(self.period_id)
    end
    
    group_mismatch = (self.group_id != self.root_item.group_id)		

    for recipient in participants
      p = recipient
      logger.info("Item#emailit person #{p.id} explanation for mailing: #{p.explanation}")
      if recipient.no_email
        logger.info("Item#emailit #{recipient.id}:#{recipient.name} is blocking all email, so skipping")
        next        
      elsif recipient.status != 'active'
        logger.info("Item#emailit #{recipient.id}:#{recipient.name} is not active, so skipping")
        next
      elsif recipient.email.to_s == ''
        logger.info("Item#emailit #{recipient.id}:#{recipient.name} has no e-mail, so skipping")
        next
      #elsif not group
      #  next
      end  

      send_it = true
        
      #elsif self.dialog_id.to_i > 0 and recipient.forum_email=='instant'
      #  #-- A discussion message
      #  logger.info("Item#emailit #{recipient.id}:#{recipient.name} discussion item for discussion #{self.dialog_id}")
      #  send_it = true
      #elsif self.dialog_id.to_i == 0 and in_subgroup and recipient.subgroup_email=='instant'
      #  #-- A subgroup message
      #  logger.info("Item#emailit #{recipient.id}:#{recipient.name} subgroup item (#{self.show_subgroup})")
      #  send_it = true
      #elsif self.dialog_id.to_i == 0 and (subgroup_none or self.show_subgroup.to_s == '') and recipient.group_email=='instant'
      #  #-- A pure group message
      #  logger.info("Item#emailit #{recipient.id}:#{recipient.name} group item (#{self.group_id})")
      #  send_it = true
      #end  

      if send_it
        logger.info("Item#emailit sending e-mail to #{recipient.id}:#{recipient.name}")        
      else  
        logger.info("Item#emailit not e-mail to #{recipient.id}:#{recipient.name}")
        next
      end
      
      # Make sure we have an authentication token for them to log in with
      # http://yekmer.posterous.com/single-access-token-using-devise
      recipient.ensure_authentication_token!
      
      domain = 'voh.' + ROOTDOMAIN 
      group_domain = domain
      
      cdata = {}
      cdata['item'] = self
      cdata['recipient'] = recipient      
      cdata['group'] = group if group
      cdata['dialog'] = dialog if dialog
      cdata['domain'] = domain
      cdata['group_domain'] = group_domain
      cdata['is_instant'] = true
      cdata['forum_link'] = "https://#{BASEDOMAIN}/dialogs/#{VOH_DISCUSSION_ID}/slider?auth_token=#{p.authentication_token}"
      #@cdata['attachments'] = @attachments
      
      if dialog and dialog.logo.exists? then
        cdata['logo'] = "https://#{BASEDOMAIN}#{dialog.logo.url}"
      elsif group and group.logo.exists? then
       cdata['logo'] = "https://#{BASEDOMAIN}#{group.logo.url}"
      else
        cdata['logo'] = nil
      end
      logger.info("Item#emailit logo: #{cdata['logo']}")
      
      email = recipient.email
      
      msubject = "[voicesofhumanity] #{self.subject}"
      
      if self.media_type == 'video' or self.media_type == 'audio'
        content = "<a href=\"#{self.link}\" target=\"_blank\">#{self.media_type}</a>"
        content += "<br>#{self.short_content.to_s}"
      elsif self.media_type == 'picture'
        content = "<img src=\"https://#{BASEDOMAIN}/images/data/items/#{self.id}/big.jpg\" alt=\"thumbnail\"><br>"
        content += self.html_content.to_s != '' ? self.html_with_auth(recipient) : self.short_content
      else
        content = self.html_content.to_s != '' ? self.html_with_auth(recipient) : self.short_content
      end
      
      link_to = "https://#{domain}/items/#{self.id}/thread?auth_token=#{p.authentication_token}&amp;exp_item_id=#{self.id}"
      if not self.is_first_in_thread
        link_to += "#item_#{self.id}"
      end
      
      itext = ""
      itext += "<h3><a href=\"#{link_to}\">#{self.subject}</a></h3>"
      itext += "<div>"
      itext += content
      itext += "</div>"
      
      itext += "<p>by "

      if dialog and not dialog.settings_with_period["profiles_visible"]
  		  itext += self.participant ? self.participant.name : self.posted_by
  		else
  		  itext += "<a href=\"https://#{domain}/participant/#{self.posted_by}/wall?auth_token=#{p.authentication_token}\">#{self.participant ? self.participant.name : self.posted_by}</a>"
  		end
  		itext += " " + self.created_at.strftime("%Y-%m-%d %H:%M")
  		itext += " <a href=\"https://#{domain}/items/#{self.id}/view?auth_token=#{p.authentication_token}\" title=\"permalink\">#</a>"
  		
      #itext += " <a href=\"#{domain}/items/#{self.id}/unfollow?email=1&amp;auth_token=#{p.authentication_token}\">Unfollow thread</a>"
      itext += " <a href=\"https://#{domain}/items/#{self.id}/unfollow?email=1&amp;auth_token=#{p.authentication_token}\">Unfollow thread</a>"

   	  if self.intra_com.to_s != '' and self.intra_com.to_s != 'public'
        itext += " &nbsp;<span style=\"font-weight:bold;color:#44a\">This message: Only #{self.intra_com}</span>"
      end
      
      itext += "</p>"
      
      if not self.has_voted(p)
        itext += "<p>Vote here: "
        itext += "<a href=\"https://#{domain}/items/#{self.id}/view?auth_token=#{p.authentication_token}&amp;thumb=-1#thumbs#{self.id}\"><img src=\"https://voh.intermix.org/images/thumbsdownoff.jpg\" height=\"30\" width=\"30\" style=\"heigh:30px;width30px;\" alt=\"thumbs down\"/></a>&nbsp;"
        itext += "<a href=\"https://#{domain}/items/#{self.id}/view?auth_token=#{p.authentication_token}&amp;thumb=1#thumbs#{self.id}\"><img src=\"https://voh.intermix.org/images/thumbsupoff.jpg\" height=\"30\" width=\"30\" style=\"heigh:30px;width30px;\" alt=\"thumbs up\"/></a>"
        itext += "<br>When you vote, you will be taken online so you can comment or change your vote."
        itext += "</p>"
      end

      was_sent = false
      email_log = Email.create(participant_id:recipient.id, context:'instant')
      cdata['email_id'] = email_log.id
      
      email = ItemMailer.item(msubject, itext, recipient.email_address_with_name, cdata)
      
      begin
        logger.info("Item#emailit delivering email to #{recipient.id}:#{recipient.name}")
        email.deliver_now
        message_id = email.message_id
        was_sent = true
      rescue Exception => e
        logger.info("Item#emailit problem delivering email to #{recipient.id}:#{recipient.name}: #{e}")
      end
      
      if was_sent
        email_log.sent = true
        email_log.sent_at = Time.now
        email_log.save
      end
      
      #ItemDelivery.create(item_id:self.id, participant_id:recipient.id, context:'instant', sent_at: Time.now)
      
    end
    
  end

  def emailit_old1
    #-- E-mail this item to everybody who's configured to receive it
    #-- This might be either people who has an author tag found within this message's message or author tags 
    #-- and who has My Communities set to instant
    #-- or it might be people who don't have any matching tags, but who have Other Communities set to instant
    #-- Each person might be configured to receive e-mails or not 

    #tags = (self.tag_list + self.participant.tag_list).uniq

    participants = []   
    
    # mycom: will go to people who share any community with the author and who has any community tag matching a message tag
    
    allpeople = Participant.where(status: 'active').where("mycom_email='instant' or othercom_email='instant'")
    #logger.info("Item#emailit self.tag_list:#{self.tag_list}")
    #logger.info("Item#emailit self.participant.tag_list:#{self.participant.tag_list}")
    for person in allpeople
      hasmessmatch = ( person.tag_list.class == ActsAsTaggableOn::TagList and person.tag_list.length > 0 and person.tag_list.any?{|t| self.tag_list.include?(t) } )
      hascommatch = ( person.tag_list.class == ActsAsTaggableOn::TagList and person.tag_list.length > 0 and person.tag_list.any?{|t| self.participant.tag_list.include?(t) } )
      #if person.id == 1867
      #  logger.info("Item#emailit person.tag_list.class:#{person.tag_list.class}")
      #  logger.info("Item#emailit person.tag_list.length:#{person.tag_list.length}")
      #  logger.info("Item#emailit person.tag_list:#{person.tag_list}")
      #  logger.info("Item#emailit hasmessmatch:#{hasmessmatch} hascommatch:#{hascommatch}")
      #end
      if hasmessmatch and hascommatch and person.mycom_email == 'instant'
        participants << person
      elsif not (hasmessmatch and hascommatch) and person.othercom_email == 'instant'
        participants << person
      end      
    end
          
    logger.info("Item#emailit #{participants.length} people to distribute to")
    
    if self.dialog_id.to_i > 0
      dialog = Dialog.find_by_id(self.dialog_id)
    end
    if self.period_id.to_i > 0
      period = Period.find_by_id(self.period_id)
    end
    
    group_mismatch = (self.group_id != self.root_item.group_id)		

    for recipient in participants
      p = recipient
      if recipient.no_email
        logger.info("Item#emailit #{recipient.id}:#{recipient.name} is blocking all email, so skipping")
        next        
      elsif recipient.status != 'active'
        logger.info("Item#emailit #{recipient.id}:#{recipient.name} is not active, so skipping")
        next
      elsif not group
        next
      end  

      send_it = false
        
      if recipient.email.to_s == ''
        logger.info("Item#emailit #{recipient.id}:#{recipient.name} has no e-mail, so skipping")
        next
      elsif self.dialog_id.to_i > 0 and recipient.forum_email=='instant'
        #-- A discussion message
        logger.info("Item#emailit #{recipient.id}:#{recipient.name} discussion item for discussion #{self.dialog_id}")
        send_it = true
      elsif self.dialog_id.to_i == 0 and in_subgroup and recipient.subgroup_email=='instant'
        #-- A subgroup message
        logger.info("Item#emailit #{recipient.id}:#{recipient.name} subgroup item (#{self.show_subgroup})")
        send_it = true
      elsif self.dialog_id.to_i == 0 and (subgroup_none or self.show_subgroup.to_s == '') and recipient.group_email=='instant'
        #-- A pure group message
        logger.info("Item#emailit #{recipient.id}:#{recipient.name} group item (#{self.group_id})")
        send_it = true
      end  

      if send_it
        logger.info("Item#emailit sending e-mail to #{recipient.id}:#{recipient.name}")        
      else  
        logger.info("Item#emailit not e-mail to #{recipient.id}:#{recipient.name}")
        next
      end
      
      # Make sure we have an authentication token for them to log in with
      # http://yekmer.posterous.com/single-access-token-using-devise
      recipient.ensure_authentication_token!
      
      domain = 'voh.' + ROOTDOMAIN 
      group_domain = domain
      
      cdata = {}
      cdata['item'] = self
      cdata['recipient'] = recipient      
      cdata['group'] = group if group
      cdata['dialog'] = dialog if dialog
      cdata['domain'] = domain
      cdata['group_domain'] = group_domain
      #@cdata['attachments'] = @attachments
      
      if dialog and dialog.logo.exists? then
        cdata['logo'] = "#{BASEDOMAIN}#{dialog.logo.url}"
      elsif group and group.logo.exists? then
       cdata['logo'] = "#{BASEDOMAIN}#{group.logo.url}"
      else
        cdata['logo'] = nil
      end
      logger.info("Item#emailit logo: #{cdata['logo']}")
      
      email = recipient.email
      
      msubject = "[voicesofhumanity] #{self.subject}"
      
      content = self.html_content != '' ? self.html_with_auth(recipient) : self.short_content
      
      link_to = "//#{domain}/items/#{self.id}/thread?auth_token=#{p.authentication_token}&amp;exp_item_id=#{self.id}"
      if not self.is_first_in_thread
        link_to += "#item_#{self.id}"
      end
      
      itext = ""
      itext += "<h3><a href=\"#{link_to}\">#{self.subject}</a></h3>"
      itext += "<div>"
      itext += content
      itext += "</div>"
      
      itext += "<p>by "

      if dialog and not dialog.settings_with_period["profiles_visible"]
  		  itext += self.participant ? self.participant.name : self.posted_by
  		else
  		  itext += "<a href=\"//#{domain}/participant/#{self.posted_by}/wall?auth_token=#{p.authentication_token}\">#{self.participant ? self.participant.name : self.posted_by}</a>"
  		end
  		itext += " " + self.created_at.strftime("%Y-%m-%d %H:%M")
  		itext += " <a href=\"//#{domain}/items/#{self.id}/view?auth_token=#{p.authentication_token}\" title=\"permalink\">#</a>"
  		
      itext += " <a href=\"#{domain}/items/#{self.id}/unfollow?email=1&amp;auth_token=#{p.authentication_token}\">Unfollow thread</a>"
      
      itext += "</p>"
      
      if group
        #-- A group message  
        email = ItemMailer.group_item(msubject, itext, recipient.email_address_with_name, cdata)
      else    
        email = ItemMailer.item(msubject, itext, recipient.email_address_with_name, cdata)
      end

      begin
        logger.info("Item#emailit delivering email to #{recipient.id}:#{recipient.name}")
        email.deliver_now
        message_id = email.message_id
      rescue Exception => e
        logger.info("Item#emailit problem delivering email to #{recipient.id}:#{recipient.name}: #{e}")
      end
      
    end
    
  end
  
  def emailit_old2
    #-- E-mail this item to everybody who's allowed to see it, and who's configured to receive it
    #-- Group items are only available to group members. Other items are available to everybody
    #-- Each person might be configured to receive e-mails or not 

    participants = []
    if self.group_id.to_i > 0
      logger.info("Item#emailit e-mailing members of group ##{self.group_id}")
      group = Group.find_by_id(self.group_id)
      
      if group and group.is_global and self.dialog_id.to_i == 0
        # Only send Global Townhall Square group messages if they're from a moderator
        group_participant = GroupParticipant.where(group_id: self.group_id, participant_id: self.posted_by).first
        if group_participant.moderator
        else
          return
        end
      end
      
      participants = group.active_members if group
      
    else
      #logger.info("Item#emailit e-mailing forum message to everybody")
      #participants = Participant.where("(status='active' or status is null) and forum_email='instant'")
    end    
    logger.info("Item#emailit #{participants.length} people to distribute to")
    
    if self.dialog_id.to_i > 0
      dialog = Dialog.find_by_id(self.dialog_id)
    end
    if self.period_id.to_i > 0
      period = Period.find_by_id(self.period_id)
    end
    
    group_mismatch = (self.group_id != self.root_item.group_id)		

    #-- Distribute to members of the target group
    for recipient in participants
      p = recipient
      if recipient.no_email
        logger.info("Item#emailit #{recipient.id}:#{recipient.name} is blocking all email, so skipping")
        next        
      elsif recipient.status != 'active'
        logger.info("Item#emailit #{recipient.id}:#{recipient.name} is not active, so skipping")
        next
      #elsif group and not (recipient.group_email=='instant' or recipient.forum_email=='instant')
      #  logger.info("#{recipient.id}:#{recipient.name} is not set for instant group mail, so skipping")
      #  next
      elsif not group
        next
      end  
      
      # This item might be in several subgroups. Is the user in any of them? If so, use the subgroup setting rather than the general forum setting
      in_subgroup = false
      subgroup_none = false
      for subgroup_tag in self.subgroup_list
        if subgroup_tag == 'none'
          subgroup_none = true
        else
          for group_subtag in p.group_subtags
            if group_subtag.tag.to_s != '' and subgroup_tag == group_subtag.tag
              in_subgroup = true
              logger.info("Item#emailit #{recipient.id}:#{recipient.name} is in one of the item's subgroups")
              break
            end  
          end
        end  
      end

      send_it = false
        
      if recipient.email.to_s == ''
        logger.info("Item#emailit #{recipient.id}:#{recipient.name} has no e-mail, so skipping")
        next
      elsif self.dialog_id.to_i > 0 and recipient.forum_email=='instant'
        #-- A discussion message
        logger.info("Item#emailit #{recipient.id}:#{recipient.name} discussion item for discussion #{self.dialog_id}")
        send_it = true
      elsif self.dialog_id.to_i == 0 and in_subgroup and recipient.subgroup_email=='instant'
        #-- A subgroup message
        logger.info("Item#emailit #{recipient.id}:#{recipient.name} subgroup item (#{self.show_subgroup})")
        send_it = true
      elsif self.dialog_id.to_i == 0 and (subgroup_none or self.show_subgroup.to_s == '') and recipient.group_email=='instant'
        #-- A pure group message
        logger.info("Item#emailit #{recipient.id}:#{recipient.name} group item (#{self.group_id})")
        send_it = true
      end  

      if send_it
        logger.info("Item#emailit sending e-mail to #{recipient.id}:#{recipient.name}")        
      else  
        logger.info("Item#emailit not e-mail to #{recipient.id}:#{recipient.name}")
        next
      end
      
      # Make sure we have an authentication token for them to log in with
      # http://yekmer.posterous.com/single-access-token-using-devise
      recipient.ensure_authentication_token!
      
      #-- Figure out the best domain to use, with discussion and group
      if dialog
        #-- If it is in a discussion, this person possibly represents another group
        group_prefix = ''
        group_participant = GroupParticipant.where(:participant_id => recipient.id, :group_id => self.group_id).first
        if group_participant
          #-- They're a member of the group, so that's the one to use
          group_prefix = group.shortname if group
        else
          for g in dialog.active_groups
            group_participant = GroupParticipant.where(:participant_id => recipient.id,:group_id => g.id).first
            if group_participant and g.shortname.to_s != ''
              group_prefix = g.shortname
              break
            end
          end
        end
        if dialog.shortname.to_s != '' and group_prefix != ''
          domain = "#{dialog.shortname}.#{group_prefix}.#{ROOTDOMAIN}"
        elsif group_prefix != ''
          domain = "#{group_prefix}.#{ROOTDOMAIN}"
        elsif dialog.shortname.to_s != ''
          domain = "#{dialog.shortname}.#{ROOTDOMAIN}"
        else
          domain = BASEDOMAIN
        end      
      elsif group and group.shortname.to_s != ''
        #-- If it is posted in a group, that's where we'll go, whether they're a member of it or not
        domain = "#{group.shortname}.#{ROOTDOMAIN}"
      else
        domain = BASEDOMAIN
      end 
      
      group_domain = (group and group.shortname.to_s != '') ? "#{group.shortname}.#{ROOTDOMAIN}" : ROOTDOMAIN
      
      cdata = {}
      cdata['item'] = self
      cdata['recipient'] = recipient      
      cdata['group'] = group if group
      cdata['dialog'] = dialog if dialog
      cdata['domain'] = domain
      cdata['group_domain'] = group_domain
      #@cdata['attachments'] = @attachments
      
      if dialog and dialog.logo.exists? then
        cdata['logo'] = "#{BASEDOMAIN}#{dialog.logo.url}"
      elsif group and group.logo.exists? then
       cdata['logo'] = "#{BASEDOMAIN}#{group.logo.url}"
      else
        cdata['logo'] = nil
      end
      logger.info("Item#emailit logo: #{cdata['logo']}")
      
      email = recipient.email
      
      msubject = "[voicesofhumanity] #{self.subject}"
      #if group and group.shortname.to_s != '' then
      #  msubject = "[#{group.shortname}] #{self.subject}"
      #else
      #  msubject = subject
      #end  
      
      content = self.html_content != '' ? self.html_with_auth(recipient) : self.short_content
      
      itext = ""
      #itext += "<h3><a href=\"http://#{domain}/items/#{self.id}/view?auth_token=#{p.authentication_token}\">#{self.subject}</a></h3>"
      itext += "<h3><a href=\"//#{domain}/items/#{self.id}/thread?auth_token=#{p.authentication_token}&amp;exp_item_id=#{self.id}#item_#{self.id}\">#{self.subject}</a></h3>"
      itext += "<div>"
      itext += content
      itext += "</div>"
      
      itext += "<p>by "

  		#if dialog and dialog.current_period.to_i > 0 and not dialog.settings_with_period["names_visible_voting"]  and self.is_first_in_thread
  		#  itext += "[name withheld during decision period]"
      #elsif dialog and dialog.current_period.to_i == 0 and not dialog.settings_with_period["names_visible_general"] and self.is_first_in_thread
  		#  itext += "[name withheld for this discussion]"  		
  		#els
      if dialog and not dialog.settings_with_period["profiles_visible"]
  		  itext += self.participant ? self.participant.name : self.posted_by
  		else
  		  itext += "<a href=\"//#{domain}/participant/#{self.posted_by}/wall?auth_token=#{p.authentication_token}\">#{self.participant ? self.participant.name : self.posted_by}</a>"
  		end
  		itext += " " + self.created_at.strftime("%Y-%m-%d %H:%M")
  		itext += " <a href=\"//#{domain}/items/#{self.id}/view?auth_token=#{p.authentication_token}\" title=\"permalink\">#</a>"
  		
  		#itext += " Discussion: <a href=\"http://#{domain}/dialogs/#{self.dialog_id}/slider?auth_token=#{p.authentication_token}&amp;exp_item_id=#{self.id}\">#{dialog.name}</a>" if dialog
  		#itext += " Decision Period: <a href=\"http://#{domain}/dialogs/#{self.dialog_id}/slider?period_id=#{self.period_id}&auth_token=#{p.authentication_token}&amp;exp_item_id=#{self.id}\">#{period.name}</a>" if period  		
  		#itext += " Group: <a href=\"http://#{group_domain}/groups/#{self.group_id}/forum?auth_token=#{p.authentication_token}&amp;exp_item_id=#{self.id}\"#{" style=\"color:#f00\"" if group_mismatch}>#{group.name}</a>" if group
  		#subgrouplink = "http://#{group_domain}/groups/#{self.group_id}/forum?auth_token=#{p.authentication_token}&amp;exp_item_id=#{self.id}&amp;subgroup="
  		#itext += " Subgroup: #{self.show_subgroup_with_link(subgrouplink)}" if self.subgroup_list.length > 0
      itext += "</p>"
      
      if group
        #-- A group message  
        email = ItemMailer.group_item(msubject, itext, recipient.email_address_with_name, cdata)
      else    
        email = ItemMailer.item(msubject, itext, recipient.email_address_with_name, cdata)
      end

      begin
        logger.info("Item#emailit delivering email to #{recipient.id}:#{recipient.name}")
        email.deliver_now
        message_id = email.message_id
      rescue Exception => e
        logger.info("Item#emailit problem delivering email to #{recipient.id}:#{recipient.name}: #{e}")
      end
      
    end

  end
    
  def personal_twitter
    #-- Post root items to the participant's own twitter account
    
    # temporarily: problem with library
    #return
    
    return if self.short_content.to_s == ''
    return if self.posted_by.to_i == 0
    return if not self.is_first_in_thread
    @participant ||= Participant.find_by_id(self.posted_by)
    return if not ( @participant and @participant.twitter_post and @participant.twitter_username.to_s !='' and @participant.twitter_oauth_token.to_s != '' )
    
    logger.info("Item#personal_twitter needs to post for #{self.posted_by}")
    
    txt = ''
    
    permalink = "//#{BASEDOMAIN}/items/#{self.id}/view"
    
    #-- Get the shortened url from bitly
    bitlyurl = "https://api-ssl.bitly.com/v3/shorten?access_token=#{BITLY_TOKEN}&longUrl=" + Rack::Utils.escape(permalink)
    begin
      bitly_response = open(bitlyurl).read
      # { "data": [ ], "status_code": 500, "status_txt": "INVALID_ARG_ACCESS_TOKEN" }
      # { "status_code": 200, "status_txt": "OK", "data": { "long_url": "http:\/\/test2g.intermix.dev\/items\/1805\/view", "url": "http:\/\/j.mp\/1imMKf8", "hash": "1imMKf8", "global_hash": "1imMKf9", "new_hash": 0 } }
      if bitly_response != ''
        bitdata = JSON.parse(bitly_response)
        if bitdata and bitdata.has_key?("status_code") and bitdata['status_code'] == 200
           shorturl = bitdata['data']['url']
        else
          #puts "  ERROR shortening: " + bitly_response
        end 
      else
        #puts "  ERROR shortening: empty response"      
      end    
    rescue Exception => e
      #puts "  ERROR shortening: " + e.message
      logger.info("Item#personal_twitter problem shortening #{permalink}")
      shorturl = ''
    end    
    if shorturl != ''
      txt += " #{shorturl}"
    end  

    wantlength = 140 - txt.length
    txt = self.short_content[0,wantlength] + txt
    
    begin
      Twitter.configure do |config|
        config.consumer_key = TWITTER_CONSUMER_KEY
        config.consumer_secret = TWITTER_CONSUMER_SECRET
        config.oauth_token = @participant.twitter_oauth_token
        config.oauth_token_secret = @participant.twitter_oauth_secret
      end
      Twitter.update(txt)
    rescue Exception => e
      logger.info("Item#personal_twitter problem posting to twitter" + e.message)
    end     
    
  end  
  
  def create_xml
    item = {}
    item['ID'] = self.id
    item['XmlItemType'] = self.item_type
    item['Sortby1'] = ''
    item['Sortby2'] = ''
    item['Sortby3'] = ''
    item['AuthorName'] = self.posted_by
    item['DateTimePosted'] = (self.created_at ? self.created_at : Time.now).strftime("%Y-%m-%d %H:%M")
    item['Subject'] = self.subject_id
    item['HtmlBody'] = self.html_content
    item['WebLinkToOriginal'] = ''
    self.xml_content = item.to_xml  
  end  
  
  def html_with_auth(participant)
    #-- For the purpose of emailing, return html_content with added authentication token for a particular user, so they'll be logged in
    self.html_content.gsub(%r{//.*?#{ROOTDOMAIN}/[^"')<,:;\s]+}) { |s|
      if s =~ /auth_token=/
        s
      else  
        s += (s =~ /\?/) ? "&" : "?"
        s += "auth_token=#{participant.authentication_token}"
      end  
    }
  end  
  
  def root_item
    #-- Find and return the root item in the thread this item is in. Might be this very item, if it is a root
    return self if self.is_first_in_thread
    Item.find_by_id(self.first_in_thread)
  end
  
  def self.list_and_results(group=nil,dialog=nil,period_id=0,posted_by=0,posted_meta={},rated_meta={},rootonly=true,sortby='',participant=nil,regmean=true,visible_by=0,start_at='',end_at='',posted_by_country_code='',posted_by_admin1uniq='',posted_by_metro_area_id=0,rated_by_country_code='',rated_by_admin1uniq='',rated_by_metro_area_id=0,tag='',subgroup='',metabreakdown=false,withratings='',geo_level='',want_crosstalk='',posted_by_indigenous=false,posted_by_other_minority=false,posted_by_veteran=false,posted_by_interfaith=false,posted_by_refugee=false,rated_by_indigenous=false,rated_by_other_minority=false,rated_by_veteran=false,rated_by_interfaith=false,rated_by_refugee=false,posted_by_city='',rated_by_city='')
    #-- Get a bunch of items, based on complicated criteria. Add up their ratings and value within just those items.
    #-- The criteria might include meta category of posters or of a particular group of raters. metamap_id => metamap_node_id
    #-- An array is being returned, optionally sorted
    
    lstart = Time.now
    
    if group.class == Integer
      group_id = group
      if group_id > 0
        group = Group.find_by_id(group_id)
      else
        group = nil
      end  
    elsif group.class == Group
      group_id = group.id 
    elsif group.class == Array
      #-- An array of group ids 
      group_id = -1   
    else
      group_id = 0
    end    
    if dialog.class == Integer
      dialog_id = dialog
      if dialog_id > 0
        dialog = Dialog.find_by_id(dialog_id)
      else
        dialog = nil  
      end  
    elsif dialog.class == Dialog
      dialog_id = dialog.id  
    else
      dialog_id = 0
    end    
    if participant.class == Integer
      participant_id = participant
    elsif participant.class == Participant
      participant_id = participant.id
    else
      participant_id = 0
    end      
    
    logger.info("item#list_and_results group:#{group_id},dialog:#{dialog_id},period:#{period_id},posted_by:#{posted_by},posted_meta:#{posted_meta.to_s},rated_meta:#{rated_meta.to_s},rootonly:#{rootonly},sortby:#{sortby},participant:#{participant_id},regmean:#{regmean}")
    
    dialog = Dialog.includes(:periods).find_by_id(dialog_id) if dialog_id.to_i > 0
    period = Period.find_by_id(period_id) if period_id.to_i > 0

    itemsproc = {}  # Stats for each item
    extras = {}     # Some addtional explanations
    
    items = Item.where(nil)
    
    items = items.where("items.group_id = #{group_id} or items.first_in_thread_group_id = #{group_id}") if group_id.to_i > 0
    items = items.where("items.group_id in (#{group.join(',')}) or items.first_in_thread_group_id in (#{group.join(',')})") if group_id.to_i < 0
    
    items = items.where("items.dialog_id = ?", dialog_id) if dialog_id.to_i > 0
    items = items.where("items.dialog_id = 0 or items.dialog_id is null") if dialog_id.to_i < 0

    items = items.where("items.period_id = ?", period_id) if period_id.to_i > 0  
    
    items = items.where("geo_level = ? or geo_level is null or geo_level = ''", geo_level) if (geo_level.to_s != '' and geo_level != 'all')
    
    num_items_total = items.length if regmean
    
    if tag.class == Array and tag.length > 0
      items = items.tagged_with(tag, :on => :tags, :match_all => true)
    elsif tag.class == String and tag != ''
      items = items.tagged_with(tag, :on => :tags)
    end
    
    if subgroup == '*' or subgroup == ''
      #-- All messages, do nothing
    elsif subgroup == 'my'
      #-- The users subgroups only, and messages initially without subgroup. 
      user_and_none_subgroups = group.mysubtags(participant) + ['none']
      items = items.tagged_with(user_and_none_subgroups, :on => :subgroups, :any => true)
    elsif subgroup == 'no'  
      #-- No subgroup messages at all
      all_subgroups = group.group_subtags.collect{|s| s.tag} - ['none']
      items = items.tagged_with(all_subgroups, :on => :subgroups, :exclude => true)      
    elsif subgroup != ''
      #-- Only messages for a particular subgroup
      items = items.tagged_with(subgroup, :on => :subgroups)
    end    
    
    #items = items.where("is_first_in_thread=1") if rootonly
    items = items.where(:posted_by => posted_by) if posted_by.to_i > 0
    #items = items.where(:first_in_thread => root_id) if root_id.to_i > 0
    items = items.where("items.created_at>='#{start_at.strftime("%Y-%m-%d %H:%M:%S")}'") if start_at.to_s != ''
    items = items.where("items.created_at<='#{end_at.strftime("%Y-%m-%d %H:%M:%S")}'") if end_at.to_s != ''

    #-- We'll add up the stats, but we're including the overall rating summary anyway
    # trying to leave this out, to make the query more simple
    #items = items.includes([:dialog,:group,:period,:item_rating_summary])

    items = items.includes(:participant=>{:metamap_node_participants=>:metamap_node}).references(:participant)
    #items = items.joins(:participant=>{:metamap_node_participants=>:metamap_node})
    #items = items.joins("left join participants on participants.id=items.posted_by")
    #items = items.joins("left join metamap_node_participants on metamap_node_participants.participant_id=items.posted_by")
    #items = items.joins("left join metamap_nodes on metamap_nodes.id=metamap_node_participants.metamap_node_id")

    
    if participant_id.to_i > 0
      #-- If a participant_id is given, we'll include that person's rating for each item, if there is any
      items = items.joins("left join ratings r_has on (r_has.item_id=items.id and r_has.participant_id=#{participant_id})")
      items = items.select("items.*,r_has.participant_id as hasrating,r_has.approval as rateapproval,r_has.interest as rateinterest,'' as explanation")
      
      # withratings is either 'no' for messages not yet rated by this person, 'yes' for only rated messages, or blank for any messages, rated or not      
      if withratings == 'yes'
        items = items.where("r_has.participant_id>0")
      elsif withratings == 'no'
        items = items.where("r_has.participant_id is null or r_has.participant_id = 0")        
      end    
    end

    if posted_by_country_code != '0' and posted_by_country_code != ''
      items = items.where("participants.country_code=?",posted_by_country_code)
    end 
    if posted_by_metro_area_id != 0 and posted_by_metro_area_id != '0' and posted_by_metro_area_id != ''
      items = items.where("participants.metro_area_id=?",posted_by_metro_area_id)
    elsif posted_by_admin1uniq != '' and posted_by_admin1uniq != '0'
      items = items.where("participants.admin1uniq=?",posted_by_admin1uniq)
    end  
    
    if posted_by_city != ''
      items = items.where("participants.city=?",posted_by_city)
    end
    if rated_by_city != ''
      items = items.where("(select count(*) from ratings r_geo inner join participants r_p_geo on (r_geo.participant_id=r_p_geo.id and r_p_geo.city=?) where r_geo.item_id=items.id)>0",rated_by_city)
    end
    
    if posted_by_indigenous
      items = items.where("participants.indigenous=1")
    end
    if posted_by_other_minority
      items = items.where("participants.other_minority=1")
    end
    if posted_by_veteran
      items = items.where("participants.veteran=1")
    end
    if posted_by_interfaith
      items = items.where("participants.interfaith=1")
    end
    if posted_by_refugee
      items = items.where("participants.refugee=1")
    end
    if rated_by_indigenous
      items = items.where("(select count(*) from ratings r_geo inner join participants r_p_geo on (r_geo.participant_id=r_p_geo.id and r_p_geo.indigenous=1) where r_geo.item_id=items.id)>0")
    end
    if rated_by_other_minority
      items = items.where("(select count(*) from ratings r_geo inner join participants r_p_geo on (r_geo.participant_id=r_p_geo.id and r_p_geo.other_minority=1) where r_geo.item_id=items.id)>0")
    end
    if rated_by_veteran
      items = items.where("(select count(*) from ratings r_geo inner join participants r_p_geo on (r_geo.participant_id=r_p_geo.id and r_p_geo.veteran=1) where r_geo.item_id=items.id)>0")
    end
    if rated_by_interfaith
      items = items.where("(select count(*) from ratings r_geo inner join participants r_p_geo on (r_geo.participant_id=r_p_geo.id and r_p_geo.interfaith=1) where r_geo.item_id=items.id)>0")
    end
    if rated_by_refugee
      items = items.where("(select count(*) from ratings r_geo inner join participants r_p_geo on (r_geo.participant_id=r_p_geo.id and r_p_geo.refugee=1) where r_geo.item_id=items.id)>0")
    end

    if rated_by_metro_area_id != 0 and rated_by_metro_area_id != '0' and rated_by_metro_area_id != ''
      items = items.where("(select count(*) from ratings r_geo inner join participants r_p_geo on (r_geo.participant_id=r_p_geo.id and r_p_geo.metro_area_id='#{rated_by_metro_area_id}') where r_geo.item_id=items.id)>0")
    elsif rated_by_admin1uniq != '' and rated_by_admin1uniq != '0'
      items = items.where("(select count(*) from ratings r_geo inner join participants r_p_geo on (r_geo.participant_id=r_p_geo.id and r_p_geo.admin1uniq='#{rated_by_admin1uniq}') where r_geo.item_id=items.id)>0")
    elsif rated_by_country_code != '0' and rated_by_country_code != ''
      items = items.where("(select count(*) from ratings r_geo inner join participants r_p_geo on (r_geo.participant_id=r_p_geo.id and r_p_geo.country_code='#{rated_by_country_code}') where r_geo.item_id=items.id)>0")
    end  
    
    if posted_meta
      posted_meta.each do |metamap_id,metamap_node_id| 
        if metamap_node_id.to_i > 0
          #-- Items must be posted by a participant in a particular meta category
          items = items.joins("inner join metamap_node_participants p_mnp_#{metamap_id} on (p_mnp_#{metamap_id}.participant_id=items.posted_by and p_mnp_#{metamap_id}.metamap_id=#{metamap_id} and p_mnp_#{metamap_id}.metamap_node_id=#{metamap_node_id})")
        end
      end
    end
    if rated_meta
      rated_meta.each do |metamap_id,metamap_node_id| 
        if metamap_node_id.to_i > 0
          #-- Items must be rated, at least once, by a participant in a particular meta category
          items = items.where("(select count(*) from ratings r_#{metamap_id} inner join participants r_p_#{metamap_id} on (r_#{metamap_id}.participant_id=r_p_#{metamap_id}.id) inner join metamap_node_participants r_mnp_#{metamap_id} on (r_mnp_#{metamap_id}.participant_id=r_p_#{metamap_id}.id and r_mnp_#{metamap_id}.metamap_node_id=#{metamap_node_id}) where r_#{metamap_id}.item_id=items.id)>0")
        end
      end
    end
    
    if false and visible_by.to_i > 0
      #-- Only items that a certain user has a right to see. I.e. mainly groups he's in
      gpin = GroupParticipant.where("participant_id=#{visible_by}")
      xgpin = '999999'
      for gp in gpin
        xgpin += "," if xgpin != ''
        xgpin += "#{gp.group_id}"
      end
      items = items.where("items.group_id in (#{xgpin})")
    end
        
    items = items.order("items.id")

    extras['sql'] = items.to_sql
    logger.info("item#list_and_results selected #{items.length} rows")    # with SQL: #{items.to_sql}
    #logger.info("item#list_and_results first attributes: #{items[0].attributes} if items[0] ")
    
    #-- Now we have the items. We'll sort them further down, after we have stats for them, in case we sort by that.
    #-- Even if we've asked for root only, we have all of them, including replies. Sorted out later.

    #-- Get the actual ratings
    ratings = Rating.where(nil)
    ratings = ratings.where("ratings.dialog_id=#{dialog_id}") if dialog_id.to_i > 0
    ratings = ratings.where("ratings.period_id=#{period_id}") if period_id.to_i >0
    ratings = ratings.includes(:participant).includes(:item=>:item_rating_summary)
    if rated_meta
      rated_meta.each do |metamap_id,metamap_node_id| 
        if metamap_node_id.to_i > 0
          #-- Ratings must be by a participant in a particular meta category
          ratings = ratings.joins("inner join metamap_node_participants r_mnp_#{metamap_id} on (r_mnp_#{metamap_id}.participant_id=ratings.participant_id and r_mnp_#{metamap_id}.metamap_id=#{metamap_id} and r_mnp_#{metamap_id}.metamap_node_id=#{metamap_node_id})")
        end
      end
    end
    logger.info("item#list_and_results got #{ratings.length} ratings: #{ratings.to_sql}")    
    
    if regmean
      #-- Prepare regression to the mean
      exp = "regression to the mean used.<br>"
      xitems = {}
      for item in items
        if item.is_first_in_thread
          xitems[item.id] = true
        end
      end
      #xrates = Rating.scoped
      #xrates = xrates.where("ratings.group_id = ?", group_id) if group_id.to_i > 0
      #xrates = xrates.where("ratings.dialog_id = ?", dialog_id) if dialog_id.to_i > 0
      #xrates = xrates.where("ratings.period_id = ?", period_id) if period_id.to_i > 0  
      xrates = ratings
      num_interest = 0
      num_approval = 0
      tot_interest = 0 
      tot_approval = 0
      item_int_uniq = {}
      item_app_uniq = {}
      for xrate in xrates
        if xitems[xrate.item_id]
          num_interest += 1 if xrate.interest
          num_approval += 1 if xrate.approval
          tot_interest += xrate.interest.to_i if xrate.interest
          tot_approval += xrate.approval.to_i if xrate.approval
          item_int_uniq[xrate.item_id] = true if xrate.interest
          item_app_uniq[xrate.item_id] = true if xrate.approval
        end  
      end 
      num_int_items = item_int_uniq.length
      num_app_items = item_app_uniq.length
      avg_votes_int = num_int_items > 0 ? ( num_interest / num_int_items ).to_i : 0 
      exp += "#{num_int_items} items have interest ratings by #{num_interest} people, totalling #{tot_interest}. Average # of votes per item: #{avg_votes_int}<br>"
      if avg_votes_int > 20
        avg_votes_int = 20 
        exp += "Average # of interest votes adjusted down to 20<br>"    
      end
      if num_interest > 0
        avg_interest = 1.0 * tot_interest / num_interest 
        exp += "Average interest: #{tot_interest} / #{num_interest} = #{avg_interest}<br>"
      else
        avg_interest = 0
        exp += "Average interest: 0<br>"  
      end  
      
      avg_votes_app = num_app_items > 0 ? ( num_approval / num_app_items ).to_i : 0
      exp += "#{num_app_items} items have approval ratings by #{num_approval} people, totalling #{tot_approval}. Average # of votes per item: #{avg_votes_app}<br>"
      if avg_votes_app > 20
        avg_votes_app = 20
        exp += "Average # of approval votes adjusted down to 20<br>"            
      end  
      if num_approval > 0
        avg_approval = 1.0 * tot_approval / num_approval 
        exp += "Average approval: #{tot_approval} / #{num_approval} = #{avg_approval}<br>"
      else
        avg_approval = 0
        exp += "Average approval: 0<br>"  
      end    
      logger.info("item#list_and_results regression to mean. avg_votes_int:#{avg_votes_int} avg_interest:#{avg_interest} avg_votes_app:#{avg_votes_app} avg_approval:#{avg_approval}")
      extras['regression'] = exp
    else
       logger.info("item#list_and_results no regression to mean")
       extras['regression'] = "No regression to the mean used"
    end

    items2 = []     # The items for the next step
    
    logger.info("item#list_and_results going through #{items.length} items and #{ratings.length} ratings")    
    for item in items
      #-- Add up stats, and filter out non-roots, if necessary, into items2
      iproc = {'id'=>item.id,'name'=>(item.participant ? item.participant.name : '???'),'subject'=>item.subject,'votes'=>0,'num_interest'=>0,'tot_interest'=>0,'avg_interest'=>0.0,'num_approval'=>0,'tot_approval'=>0,'avg_approval'=>0.0,'value'=>0.0,'int_0_count'=>0,'int_1_count'=>0,'int_2_count'=>0,'int_3_count'=>0,'int_4_count'=>0,'app_n3_count'=>0,'app_n2_count'=>0,'app_n1_count'=>0,'app_0_count'=>0,'app_p1_count'=>0,'app_p2_count'=>0,'app_p3_count'=>0,'controversy'=>0,'item'=>item,'replies'=>[],'hasrating'=>0,'rateapproval'=>0,'rateinterest'=>0,'num_raters'=>0,'ratings'=>[]}
      if participant_id.to_i > 0 
        if item.respond_to?(:hasrating)
          #-- item.attributes would show all attributes, not just item.inspect
          iproc['hasrating'] = item.hasrating
          iproc['rateapproval'] = item.rateapproval
          iproc['rateinterest'] = item.rateinterest
        else
          #-- Horrible hack. Some kind of bug makes those joined fields sometimes not be there. Look them up.
          p_rating = Rating.where(:item_id=>item.id,:participant_id=>participant_id).first
          if p_rating
            iproc['hasrating'] = participant_id
            iproc['rateapproval'] = p_rating.approval
            iproc['rateinterest'] = p_rating.interest
          end
        end
      end
      for rating in ratings
        if rating.item_id == item.id
          iproc['votes'] += 1
          if rating.interest
            iproc['num_interest'] += 1
            iproc['tot_interest'] += rating.interest.to_i
            iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
            case rating.interest.to_i
            when 0
              iproc['int_0_count'] += 1
            when 1
              iproc['int_1_count'] += 1
            when 2
              iproc['int_2_count'] += 1
            when 3
              iproc['int_3_count'] += 1
            when 4
              iproc['int_4_count'] += 1
            end  
          end 
          if rating.approval     
            iproc['num_approval'] += 1
            iproc['tot_approval'] += rating.approval.to_i
            iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
            case rating.approval.to_i
            when -3
              iproc['app_n3_count'] +=1   
            when -2
              iproc['app_n2_count'] +=1   
            when -1
              iproc['app_n1_count'] +=1   
            when 0
              iproc['app_0_count'] +=1   
            when 1
              iproc['app_p1_count'] +=1   
            when 2
              iproc['app_p2_count'] +=1   
            when 3
              iproc['app_p3_count'] +=1   
            end  
          end
          iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
          
          #iproc['num_raters'] = [iproc['num_interest'],iproc['num_approval']].max
          iproc['num_raters'] += 1
          
          iproc['ratingnoregmean'] = "Average interest: #{iproc['tot_interest']} total / #{iproc['num_interest']} ratings = #{iproc['avg_interest']}<br>" + "Average approval: #{iproc['tot_approval']} total / #{iproc['num_approval']} ratings = #{iproc['avg_approval']}<br>" + "Value: #{iproc['avg_interest']} interest * #{iproc['avg_approval']} approval = #{iproc['value']}"
          
          #iproc['ratings'] << {'participant_id'=>rating.participant_id, 'group_id'=>rating.group_id, 'dialog_id'=>rating.dialog_id, 'period_id'=>rating.period_id, 'approval'=>rating.approval, 'interest'=>rating.interest, 'created_at'=>rating.created_at}
          iproc['ratings'] << rating
          
        end
      end
      iproc['controversy'] = (1.0 * ( iproc['app_n3_count'] * (-3.0 - iproc['avg_approval'])**2 + iproc['app_n2_count'] * (-2.0 - iproc['avg_approval'])**2 + iproc['app_n1_count'] * (-1.0 - iproc['avg_approval'])**2 + iproc['app_0_count'] * (0.0 - iproc['avg_approval'])**2 + iproc['app_p1_count'] * (1.0 - iproc['avg_approval'])**2 + iproc['app_p2_count'] * (2.0 - iproc['avg_approval'])**2 + iproc['app_p3_count'] * (3.0 - iproc['avg_approval'])**2 ) / iproc['num_approval']) if iproc['num_approval'] != 0
      itemsproc[item.id] = iproc
      
      if rootonly or sortby=='default'
        #-- If we need roots only
        if item.is_first_in_thread
          #-- This is a root, put it on the main list
          items2 << item  
        elsif item.first_in_thread.to_i > 0 and itemsproc[item.first_in_thread]
          #-- This is a reply, store it with the proper root
          itemsproc[item.first_in_thread]['replies'] << item
        end
      else
        items2 << item  
      end

    end
    
    logger.info("item#list_and_results we have #{items2.length} items after removing non-roots");
    
    # We're probably no longer using the global numbers, as we've added them up just now
    # ['Value','items.value desc,items.id desc'],['Approval','items.approval desc,items.id desc'],['Interest','items.interest desc,items.id desc'],['Controversy','items.controversy desc,items.id desc']  
  
    if regmean
      #-- Go through the items again and adjust them with a regression to the mean
      for item in items
        iproc = itemsproc[item.id]
        iproc['ratingwithregmean'] = ''
        if iproc['num_interest'] < avg_votes_int and iproc['num_interest'] > 0
          old_num_interest = iproc['num_interest']
          old_tot_interest = iproc['tot_interest']
          iproc['tot_interest'] += (avg_votes_int - iproc['num_interest']) * avg_interest
          iproc['num_interest'] = avg_votes_int
          iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
          iproc['ratingwithregmean'] += "int votes adjusted #{old_num_interest} -> #{iproc['num_interest']}. int total adjusted #{old_tot_interest} -> #{iproc['tot_interest']}<br>"
        end  
        if iproc['num_approval'] < avg_votes_app and iproc['num_approval'] > 0
          old_num_approval = iproc['num_approval']
          old_tot_approval = iproc['tot_approval']
          iproc['tot_approval'] += (avg_votes_app - iproc['num_approval']) * avg_approval
          iproc['num_approval'] = avg_votes_app
          iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
          iproc['ratingwithregmean'] += "app votes adjusted #{old_num_approval} -> #{iproc['num_approval']}. app total adjusted #{old_tot_approval} -> #{iproc['tot_approval']}<br>"
        end  
        iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
        iproc['ratingwithregmean'] += "Average interest: #{iproc['tot_interest']} total / #{iproc['num_interest']} ratings = #{iproc['avg_interest']}<br>" + "Average approval: #{iproc['tot_approval']} total / #{iproc['num_approval']} ratings = #{iproc['avg_approval']}<br>" + "Value: #{iproc['avg_interest']} interest * #{iproc['avg_approval']} approval = #{iproc['value']}"
        itemsproc[item.id] = iproc
      end
    end
  
    if sortby.to_s == 'default'
      #-- Fancy sort, trying to mix genders/ages. First figure out which one, if we weren't already told
      if want_crosstalk
      elsif dialog and period and dialog.active_period.id == period.id and period.crosstalk != 'none'
        want_crosstalk = period.crosstalk
      else
        want_crosstalk = 'gender'
      end
      items = Item.custom_item_sort(items2, itemsproc, participant_id, dialog, want_crosstalk)
    elsif sortby.to_s == '*value*' or sortby.to_s == ''
      logger.info("item#list_and_results sorting by value")
      itemsproc_sorted = itemsproc.sort {|a,b| [b[1]['value'],b[1]['votes'],b[1]['id']]<=>[a[1]['value'],a[1]['votes'],a[1]['id']]}
      outitems = []
      itemsproc_sorted.each do |item_id,iproc|
        if (not rootonly) or iproc['item'].is_first_in_thread
          outitems << iproc['item']
        end
      end
      items = outitems
    elsif sortby == '*approval*'      
      itemsproc_sorted = itemsproc.sort {|a,b| [b[1]['avg_approval'],b[1]['votes'],b[1]['id']]<=>[a[1]['avg_approval'],a[1]['votes'],a[1]['id']]}
      outitems = []
      itemsproc_sorted.each do |item_id,iproc|
        if (not rootonly) or iproc['item'].is_first_in_thread
          outitems << iproc['item']
        end
      end
      items = outitems
    elsif sortby == '*interest*'      
      itemsproc_sorted = itemsproc.sort {|a,b| [b[1]['avg_interest'],b[1]['votes'],b[1]['id']]<=>[a[1]['avg_interest'],a[1]['votes'],a[1]['id']]}
      outitems = []
      itemsproc_sorted.each do |item_id,iproc|
        if (not rootonly) or iproc['item'].is_first_in_thread
          outitems << iproc['item']
        end
      end
      items = outitems
    elsif sortby == '*controversy*'      
      itemsproc_sorted = itemsproc.sort {|a,b| [b[1]['controversy'],b[1]['votes'],b[1]['id']]<=>[a[1]['controversy'],a[1]['votes'],a[1]['id']]}
      outitems = []
      itemsproc_sorted.each do |item_id,iproc|
        if (not rootonly) or iproc['item'].is_first_in_thread
          outitems << iproc['item']
        end
      end
      items = outitems
    elsif sortby[0,5] == 'meta:'
      #-- NB: Not sure this is working !!
      metamap_id = sortby[5,10].to_i
      sortby = "metamap_nodes.name"
      items = items2.where("metamap_nodes.metamap_id=#{metamap_id}")
    elsif items2.class != Array
      items = items2.order(sortby)
    elsif sortby == 'items.id desc'
      items = items2.sort {|a,b| b.id <=> a.id}
    else  
      #-- Already sorted in ID order
      logger.info("item#list_and_results leaving sorted by ID")
      items = items2
    end

    logger.info("item#list_and_results returning #{items.length} items, #{itemsproc.length} itemsproc");
    
    if metabreakdown
      extras['meta'] = results_meta_breakdown(dialog,period,group,regmean)
    end  
    
    duration = (Time.now - lstart) * 1000
    logger.info("item#list_and_results elapsed time: #{duration} milliseconds")
    
    return [items, itemsproc, extras]
    
  end
  
  def self.get_items(crit,current_participant,rootonly=true)
    #-- Get the items and records that match a certain criteria. Mainly for geoslider
  
    logger.info("item#get_items crit:#{crit}")
  
    # Start preparing the queries
    items = Item.where(nil)
    ratings = Rating.where(nil)
    title = ''

    # Date period
    if crit.has_key?(:datefromuse) and crit[:datefromuse].to_s != ''
      if crit[:datefromuse].class == Date
        datefromuse = crit[:datefromuse].dup.strftime("%Y-%m-%d")
      else
        datefromuse = crit[:datefromuse].dup.to_s
      end
      datefromuse << ' 00:00:00'
      items = items.where("items.created_at >= ?", datefromuse)
      logger.info("item#get_items from date: #{crit[:datefromuse]}")
    end
    if crit.has_key?(:datefromto) and crit[:datefromto].to_s != ''
      if crit[:datefromto].class == Date
        datefromto = crit[:datefromto].dup.strftime("%Y-%m-%d")
      else
        datefromto = crit[:datefromto].dup.to_s
      end
      datefromto << ' 23:59:59'
      items = items.where("items.created_at <= ?", datefromto)
      logger.info("item#get_items to date: #{crit[:datefromto]}")
    end
    # Don't look at date for ratings

    items = items.includes(:participant=>{:metamap_node_participants=>:metamap_node}).references(:participant)
    ratings = ratings.includes(:participant=>{:metamap_node_participants=>:metamap_node}).references(:participant)
    
    # Don't worry about groups any more
    title = ''
  
    # Either posted in that geo level or no geo level given
    #items = items.where("geo_level = ? or geo_level is null or geo_level = ''", crit[:geo_level]) if (crit[:geo_level].to_s != '' and crit[:geo_level] != 'all')
  
    if crit[:geo_level] == 'city'
      if current_participant.city.to_s != ''
        items = items.where("participants.city=?",current_participant.city)
        ratings = ratings.where("participants.city=?",current_participant.city)
        title += "#{current_participant.city}"
      else
        items = items.where("1=0")
        ratings = ratings.where("1=0")
        title += "Unknown City"
      end  
    elsif crit[:geo_level] == 'county'
      if current_participant.admin2uniq.to_s != '' and current_participant.geoadmin2
        items = items.where("participants.admin2uniq=?",current_participant.admin2uniq)
        ratings = ratings.where("participants.admin2uniq=?",current_participant.admin2uniq)
        title += "#{current_participant.geoadmin2.name}" 
      else
        items = items.where("1=0")
        ratings = ratings.where("1=0")
        title += "Unknown County"
      end  
    elsif crit[:geo_level] == 'metro'
      if current_participant.metro_area_id.to_i > 0 and current_participant.metro_area
        items = items.where("participants.metro_area_id=?",current_participant.metro_area_id)
        ratings = ratings.where("participants.metro_area_id=?",current_participant.metro_area_id)
        title += "#{current_participant.metro_area.name}"
      else
        items = items.where("1=0")
        ratings = ratings.where("1=0")
        title += "Unknown Metro Area"
      end  
    elsif crit[:geo_level] == 'state'  
      if current_participant.admin1uniq.to_s != '' and current_participant.geoadmin1
        items = items.where("participants.admin1uniq=?",current_participant.admin1uniq)
        ratings = ratings.where("participants.admin1uniq=?",current_participant.admin1uniq)
        title += "#{current_participant.geoadmin1.name}"
      else
        items = items.where("1=0")
        ratings = ratings.where("1=0")
        title += "Unknown State"
      end  
    elsif crit[:geo_level] == 'nation'
      items = items.where("participants.country_code=?",current_participant.country_code)
      ratings = ratings.where("participants.country_code=?",current_participant.country_code)
      title += "#{current_participant.geocountry.name}"
    elsif crit[:geo_level] == 'planet'
      title += "Planet Earth"  
    elsif crit[:geo_level] == 'all'
      title += "All Perspectives"
    end
    
    if crit[:conversation_id].to_i > 0
      items = items.where("items.conversation_id=#{crit[:conversation_id]}")
      ratings = ratings.where(conversation_id: crit[:conversation_id])
      #ratings = ratings.where("participants.indigenous=1")
      @conversation = Conversation.find_by_id(crit[:conversation_id])
      #title += " | #{@conversation.name}" if @conversation
      items = items.where("intra_conv='public' or intra_conv='#{@conversation.shortname}'")
    else
      items = items.where("intra_conv='public'")        
    end
    
    if crit[:gender].to_i != 0
      items = items.joins("inner join metamap_node_participants p_mnp_3 on (p_mnp_3.participant_id=items.posted_by and p_mnp_3.metamap_id=3 and p_mnp_3.metamap_node_id=#{crit[:gender]})")   
      ratings = ratings.joins("inner join metamap_node_participants p_mnp_3 on (p_mnp_3.participant_id=ratings.participant_id and p_mnp_3.metamap_id=3 and p_mnp_3.metamap_node_id=#{crit[:gender]})")   
    end
    if crit[:age].to_i != 0
      items = items.joins("inner join metamap_node_participants p_mnp_5 on (p_mnp_5.participant_id=items.posted_by and p_mnp_5.metamap_id=5 and p_mnp_5.metamap_node_id=#{crit[:age]})")   
      ratings = ratings.joins("inner join metamap_node_participants p_mnp_5 on (p_mnp_5.participant_id=ratings.participant_id and p_mnp_5.metamap_id=5 and p_mnp_5.metamap_node_id=#{crit[:age]})")   
    end

    if crit[:gender].to_i > 0 and crit[:age].to_i == 0
      gender = MetamapNode.find_by_id(crit[:gender].to_i)
      title += " | #{gender.name_as_group}"
    elsif crit[:gender].to_i == 0 and crit[:age].to_i > 0
      age = MetamapNode.find_by_id(crit[:age].to_i)
      title += " | #{age.name_as_group}"
    elsif crit[:gender].to_i > 0 and crit[:age].to_i > 0
      gender = MetamapNode.find_by_id(crit[:gender].to_i)
      age = MetamapNode.find_by_id(crit[:age].to_i)
      xtit = gender.name_as_group
      xtit2 = xtit[0..8] + age.name.capitalize + ' ' + xtit[9..100]
      title += " | #{xtit2}"    
    elsif not crit[:show_result]
      title += " | Voice of Humanity"
    end
    
    # tags
    if crit['in'] == 'conversation' and @conversation
      # Tags in a conversation are treated a bit differently      
      # representing_com messages can only be seen if one is in that comtag
      if crit[:comtag].to_s != '' and crit[:comtag].to_s != '*my*'
        items = items.where("representing_com='public' or lower(representing_com)='#{crit[:comtag].downcase}'")
      else
        items = items.where("representing_com='public'")        
      end
      # What about this now??
      #if @conversation.together_apart == 'together'
      #  # Don't care about comtags at all
      #elsif crit[:comtag].to_s != '' and crit[:comtag].to_s != '*my*'
      #  # Only show what's for the user's perspective
      #  if current_participant.tag_list_downcase.include?(crit[:comtag].downcase)
      #    items = items.where(representing_com: crit[:comtag].downcase)       
      #  end
      #end
    elsif crit[:comtag].to_s == '*my*'
      title += " | My Communities"
      plist = ''
      comtag_list = ''
      comtags = {}
      ps = {}
      for tag in current_participant.tag_list_downcase
        comtags[tag] = true
        for p in Participant.tagged_with(tag)
          ps[p.id] = true
        end
      end
      comtag_list = comtags.collect{|k, v| "'@#{k}'"}.join(',')
      plist = ps.collect{|k, v| k}.join(',')
      if plist != ''
        items = items.where("participants.id in (#{plist})")
      else
        items = items.where("1=0")
      end      
      
      # show items from members of any of my groups
      items = items.where("intra_com='public' or intra_com in (#{comtag_list})")
      
    elsif crit[:comtag].to_s != ''
      title += " | @#{crit[:comtag]}"
      # does the current user have that tag?
      has_tag = false
      for tag in current_participant.tag_list_downcase
        if tag == crit[:comtag].downcase
          has_tag = true
        end
      end
      if has_tag
        title += " <input type=\"button\" value=\"leave\" onclick=\"joinleave('#{crit[:comtag]}')\" id=\"comtagjoin\">"
      else
        title += " <input type=\"button\" value=\"join\" onclick=\"joinleave('#{crit[:comtag]}')\" id=\"comtagjoin\">"
      end
      plist = Participant.tagged_with(crit[:comtag]).collect {|p| p.id}.join(',')
      if plist != ''
        items = items.where("participants.id in (#{plist})")
      else
        items = items.where("1=0")
      end

      # Show items that either are public, or specifically for this community
      items = items.where("intra_com='public' or intra_com='@#{crit[:comtag]}'")

    #elsif crit[:posted_by].to_i == 0 and not (crit.has_key?(:from) and crit[:from] == 'mail')
    elsif crit[:posted_by].to_i == 0
      
      # show only public items, if there's no community specified, unless we're seeing somebody's wall, or it is a bulk mailing
      items = items.where("intra_com='public'")
      
    end
    
    if crit.has_key?(:conversation_id) and crit[:conversation_id].to_i > 0
      # Skip tags if we're in a conversation
    elsif crit[:messtag].to_s != ''
      title += " | ##{crit[:messtag]}"
      items = items.tagged_with(crit[:messtag])      
    end    
    
    if crit.has_key?(:nvaction) and crit[:nvaction] === true
      items = items.tagged_with('nvaction')      
      logger.info("item#get_items nvaction:#{crit[:nvaction]} include nvaction")
    elsif crit.has_key?(:nvaction) and crit[:nvaction] === false
      if crit.has_key?(:nvaction_included) and crit[:nvaction_included] === false
        items = items.tagged_with('nvaction', exclude: true)  
        logger.info("item#get_items nvaction:#{crit[:nvaction]} exclude nvaction")
      end          
      logger.info("item#get_items nvaction:#{crit[:nvaction]} nvaction_included:#{crit[:nvaction_included]}")
    end
    logger.info("item#get_items crit:#{crit.inspect}")
      
    if rootonly
      # Leaving non-roots in there. Will be sorted out in get_itemsproc
      #items = items.where("is_first_in_thread=1")
      # So, if we limit items to rootonly, we might have ratings for other items too
      # That should hopefully not matter.
    end

    if crit[:posted_by].to_i > 0
      # Only posts for a particular user, like for their wall
      items = items.where(posted_by: crit[:posted_by])
    end

    #-- If a participant_id is given, we'll include that person's rating for each item, if there is any
    if current_participant
      items = items.joins("left join ratings r_has on (r_has.item_id=items.id and r_has.participant_id=#{current_participant.id})")
      items = items.select("items.*,r_has.participant_id as hasrating,r_has.approval as rateapproval,r_has.interest as rateinterest,'' as explanation")
    end
    
    #puts("sql: #{items.to_sql}")
  
    logger.info("item#get_items #{items.length if items} items and #{ratings.length if ratings} ratings")
  
    return items,ratings,title
  end
  
  def self.get_itemsproc(items,ratings,participant_id,rootonly=false)
    # Add things up based on given items and ratings. Return itemsproc
    logger.info("item#get_itemsproc start with #{items.length} items and #{ratings.length} ratings")
    
    regmean = true
    sortby = ''

    itemsproc = {}  # Stats for each item
    extras = {}     # Some addtional explanations
    
    if regmean
      #-- Prepare regression to the mean
      exp = "regression to the mean used.<br>"
      xitems = {}
      for item in items
        #if item.is_first_in_thread
          xitems[item.id] = true
        #end
      end
      #xrates = Rating.scoped
      #xrates = xrates.where("ratings.group_id = ?", group_id) if group_id.to_i > 0
      #xrates = xrates.where("ratings.dialog_id = ?", dialog_id) if dialog_id.to_i > 0
      #xrates = xrates.where("ratings.period_id = ?", period_id) if period_id.to_i > 0  
      xrates = ratings
      num_interest = 0
      num_approval = 0
      tot_interest = 0 
      tot_approval = 0
      item_int_uniq = {}
      item_app_uniq = {}
      for xrate in xrates
        if xitems[xrate.item_id]
          num_interest += 1 if xrate.interest
          num_approval += 1 if xrate.approval
          tot_interest += xrate.interest.to_i if xrate.interest
          tot_approval += xrate.approval.to_i if xrate.approval
          item_int_uniq[xrate.item_id] = true if xrate.interest
          item_app_uniq[xrate.item_id] = true if xrate.approval
        end  
      end 
      num_int_items = item_int_uniq.length
      num_app_items = item_app_uniq.length
      avg_votes_int = num_int_items > 0 ? ( num_interest / num_int_items ).to_i : 0 
      exp += "#{num_int_items} items have interest ratings by #{num_interest} people, totalling #{tot_interest}. Average # of votes per item: #{avg_votes_int}<br>"
      if avg_votes_int > 20
        avg_votes_int = 20 
        exp += "Average # of interest votes adjusted down to 20<br>"    
      end
      if num_interest > 0
        avg_interest = 1.0 * tot_interest / num_interest 
        exp += "Average interest: #{tot_interest} / #{num_interest} = #{avg_interest}<br>"
      else
        avg_interest = 0
        exp += "Average interest: 0<br>"  
      end  
      
      avg_votes_app = num_app_items > 0 ? ( num_approval / num_app_items ).to_i : 0
      exp += "#{num_app_items} items have approval ratings by #{num_approval} people, totalling #{tot_approval}. Average # of votes per item: #{avg_votes_app}<br>"
      if avg_votes_app > 20
        avg_votes_app = 20
        exp += "Average # of approval votes adjusted down to 20<br>"            
      end  
      if num_approval > 0
        avg_approval = 1.0 * tot_approval / num_approval 
        exp += "Average approval: #{tot_approval} / #{num_approval} = #{avg_approval}<br>"
      else
        avg_approval = 0
        exp += "Average approval: 0<br>"  
      end    
      logger.info("item#get_itemsproc regression to mean. avg_votes_int:#{avg_votes_int} avg_interest:#{avg_interest} avg_votes_app:#{avg_votes_app} avg_approval:#{avg_approval}")
      extras['regression'] = exp
    else
       logger.info("item#get_itemsproc no regression to mean")
       extras['regression'] = "No regression to the mean used"
    end

    items2 = []     # The items for the next step
    
    logger.info("item#get_itemsproc going through #{items.length} items and #{ratings.length} ratings")    
    for item in items
      #-- Add up stats, and filter out non-roots, if necessary, into items2
      iproc = {'id'=>item.id,'name'=>(item.participant ? item.participant.name : '???'),'subject'=>item.subject,'votes'=>0,'num_interest'=>0,'tot_interest'=>0,'avg_interest'=>0.0,'num_approval'=>0,'tot_approval'=>0,'avg_approval'=>0.0,'value'=>0.0,'int_0_count'=>0,'int_1_count'=>0,'int_2_count'=>0,'int_3_count'=>0,'int_4_count'=>0,'app_n3_count'=>0,'app_n2_count'=>0,'app_n1_count'=>0,'app_0_count'=>0,'app_p1_count'=>0,'app_p2_count'=>0,'app_p3_count'=>0,'controversy'=>0,'item'=>item,'replies'=>[],'hasrating'=>0,'rateapproval'=>0,'rateinterest'=>0,'num_raters'=>0,'ratings'=>[]}
      if participant_id.to_i > 0 
        if item.respond_to?(:hasrating)
          #-- item.attributes would show all attributes, not just item.inspect
          iproc['hasrating'] = item.hasrating
          iproc['rateapproval'] = item.rateapproval
          iproc['rateinterest'] = item.rateinterest
        else
          #-- Horrible hack. Some kind of bug makes those joined fields sometimes not be there. Look them up.
          p_rating = Rating.where(:item_id=>item.id,:participant_id=>participant_id).first
          if p_rating
            iproc['hasrating'] = participant_id
            iproc['rateapproval'] = p_rating.approval
            iproc['rateinterest'] = p_rating.interest
          end
        end
      end
      for rating in ratings
        if rating.item_id == item.id
          iproc['votes'] += 1
          if rating.interest
            iproc['num_interest'] += 1
            iproc['tot_interest'] += rating.interest.to_i
            iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
            case rating.interest.to_i
            when 0
              iproc['int_0_count'] += 1
            when 1
              iproc['int_1_count'] += 1
            when 2
              iproc['int_2_count'] += 1
            when 3
              iproc['int_3_count'] += 1
            when 4
              iproc['int_4_count'] += 1
            end  
          end 
          if rating.approval     
            iproc['num_approval'] += 1
            iproc['tot_approval'] += rating.approval.to_i
            iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
            case rating.approval.to_i
            when -3
              iproc['app_n3_count'] +=1   
            when -2
              iproc['app_n2_count'] +=1   
            when -1
              iproc['app_n1_count'] +=1   
            when 0
              iproc['app_0_count'] +=1   
            when 1
              iproc['app_p1_count'] +=1   
            when 2
              iproc['app_p2_count'] +=1   
            when 3
              iproc['app_p3_count'] +=1   
            end  
          end
          iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
          
          #iproc['num_raters'] = [iproc['num_interest'],iproc['num_approval']].max
          iproc['num_raters'] += 1
          
          iproc['ratingnoregmean'] = "Average interest: #{iproc['tot_interest']} total / #{iproc['num_interest']} ratings = #{iproc['avg_interest']}<br>" + "Average approval: #{iproc['tot_approval']} total / #{iproc['num_approval']} ratings = #{iproc['avg_approval']}<br>" + "Value: #{iproc['avg_interest']} interest * #{iproc['avg_approval']} approval = #{iproc['value']}"
          
          #iproc['ratings'] << {'participant_id'=>rating.participant_id, 'group_id'=>rating.group_id, 'dialog_id'=>rating.dialog_id, 'period_id'=>rating.period_id, 'approval'=>rating.approval, 'interest'=>rating.interest, 'created_at'=>rating.created_at}
          iproc['ratings'] << rating
          
        end
      end
      iproc['controversy'] = (1.0 * ( iproc['app_n3_count'] * (-3.0 - iproc['avg_approval'])**2 + iproc['app_n2_count'] * (-2.0 - iproc['avg_approval'])**2 + iproc['app_n1_count'] * (-1.0 - iproc['avg_approval'])**2 + iproc['app_0_count'] * (0.0 - iproc['avg_approval'])**2 + iproc['app_p1_count'] * (1.0 - iproc['avg_approval'])**2 + iproc['app_p2_count'] * (2.0 - iproc['avg_approval'])**2 + iproc['app_p3_count'] * (3.0 - iproc['avg_approval'])**2 ) / iproc['num_approval']) if iproc['num_approval'] != 0
      itemsproc[item.id] = iproc
      
      if (rootonly or sortby=='default')
        #-- If we need roots only
        if item.is_first_in_thread
          #-- This is a root, put it on the main list
          items2 << item  
        elsif item.first_in_thread.to_i > 0 and itemsproc[item.first_in_thread]
          #-- This is a reply, store it with the proper root
          itemsproc[item.first_in_thread]['replies'] << item
        end
      else
        items2 << item  
      end

    end
    
    logger.info("item#get_itemsproc we have #{items2.length} items after removing non-roots");
    
    # We're probably no longer using the global numbers, as we've added them up just now
    # ['Value','items.value desc,items.id desc'],['Approval','items.approval desc,items.id desc'],['Interest','items.interest desc,items.id desc'],['Controversy','items.controversy desc,items.id desc']  
  
    if regmean
      #-- Go through the items again and adjust them with a regression to the mean
      for item in items
        iproc = itemsproc[item.id]
        iproc['ratingwithregmean'] = ''
        if iproc['num_interest'] < avg_votes_int and iproc['num_interest'] > 0
          old_num_interest = iproc['num_interest']
          old_tot_interest = iproc['tot_interest']
          iproc['tot_interest'] += (avg_votes_int - iproc['num_interest']) * avg_interest
          iproc['num_interest'] = avg_votes_int
          iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
          iproc['ratingwithregmean'] += "int votes adjusted #{old_num_interest} -> #{iproc['num_interest']}. int total adjusted #{old_tot_interest} -> #{iproc['tot_interest']}<br>"
        end  
        if iproc['num_approval'] < avg_votes_app and iproc['num_approval'] > 0
          old_num_approval = iproc['num_approval']
          old_tot_approval = iproc['tot_approval']
          iproc['tot_approval'] += (avg_votes_app - iproc['num_approval']) * avg_approval
          iproc['num_approval'] = avg_votes_app
          iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
          iproc['ratingwithregmean'] += "app votes adjusted #{old_num_approval} -> #{iproc['num_approval']}. app total adjusted #{old_tot_approval} -> #{iproc['tot_approval']}<br>"
        end  
        iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
        iproc['ratingwithregmean'] += "Average interest: #{iproc['tot_interest']} total / #{iproc['num_interest']} ratings = #{iproc['avg_interest']}<br>" + "Average approval: #{iproc['tot_approval']} total / #{iproc['num_approval']} ratings = #{iproc['avg_approval']}<br>" + "Value: #{iproc['avg_interest']} interest * #{iproc['avg_approval']} approval = #{iproc['value']}"
        itemsproc[item.id] = iproc
      end
    end

    #return(itemsproc)
    return [itemsproc, extras]
  end
  
  def self.get_sorted(items2,itemsproc,sortby,rootonly=false)
    #-- Return items sorted by something in itemsproc (value, etc.)
    
    #need: rootonly, want_crosstalk, dialog, period, participant_id
    #rootonly = false
    
    #if sortby.to_s == 'default'
    #  #-- Fancy sort, trying to mix genders/ages. First figure out which one, if we weren't already told
    #  if want_crosstalk
    #  elsif dialog and period and dialog.active_period.id == period.id and period.crosstalk != 'none'
    #    want_crosstalk = period.crosstalk
    #  else
    #    want_crosstalk = 'gender'
    #  end
    #  items = Item.custom_item_sort(items2, itemsproc, participant_id, dialog, want_crosstalk)
    if sortby.to_s == 'default'
      sortby.to_s = 'items.id desc'
    end
      
    if sortby.to_s == 'default'
      #-- Fancy sort, trying to mix genders/ages. First figure out which one, if we weren't already told
      if want_crosstalk
      elsif dialog and period and dialog.active_period.id == period.id and period.crosstalk != 'none'
        want_crosstalk = period.crosstalk
      else
        want_crosstalk = 'gender'
      end
      items = Item.custom_item_sort(items2, itemsproc, participant_id, dialog, want_crosstalk)
    elsif sortby.to_s == '*value*' or sortby.to_s == ''
      logger.info("item#get_sorted sorting by value")
      itemsproc_sorted = itemsproc.sort {|a,b| [b[1]['value'],b[1]['votes'],b[1]['id']]<=>[a[1]['value'],a[1]['votes'],a[1]['id']]}
      outitems = []
      itemsproc_sorted.each do |item_id,iproc|
        if (not rootonly) or iproc['item'].is_first_in_thread
          outitems << iproc['item']
        end
      end
      items = outitems
    elsif sortby == '*approval*'      
      itemsproc_sorted = itemsproc.sort {|a,b| [b[1]['avg_approval'],b[1]['votes'],b[1]['id']]<=>[a[1]['avg_approval'],a[1]['votes'],a[1]['id']]}
      outitems = []
      itemsproc_sorted.each do |item_id,iproc|
        if (not rootonly) or iproc['item'].is_first_in_thread
          outitems << iproc['item']
        end
      end
      items = outitems
    elsif sortby == '*interest*'      
      itemsproc_sorted = itemsproc.sort {|a,b| [b[1]['avg_interest'],b[1]['votes'],b[1]['id']]<=>[a[1]['avg_interest'],a[1]['votes'],a[1]['id']]}
      outitems = []
      itemsproc_sorted.each do |item_id,iproc|
        if (not rootonly) or iproc['item'].is_first_in_thread
          outitems << iproc['item']
        end
      end
      items = outitems
    elsif sortby == '*controversy*'      
      itemsproc_sorted = itemsproc.sort {|a,b| [b[1]['controversy'],b[1]['votes'],b[1]['id']]<=>[a[1]['controversy'],a[1]['votes'],a[1]['id']]}
      outitems = []
      itemsproc_sorted.each do |item_id,iproc|
        if (not rootonly) or iproc['item'].is_first_in_thread
          outitems << iproc['item']
        end
      end
      items = outitems
    elsif items2.class != Array
      logger.info("item#get_sorted not array, sorting query by #{sortby}")
      items = items2.order(sortby)
      outitems = []
      for item in items
        if (not rootonly) or item.is_first_in_thread
          outitems << item
        end
      end
      items = outitems
    elsif sortby == 'items.id desc'
      items = items2.sort {|a,b| b.id <=> a.id}
      outitems = []
      for item in items
        if (not rootonly) or item.is_first_in_thread
          outitems << item
        end
      end
      items = outitems
    else  
      #-- Already sorted in ID order
      logger.info("item#get_sorted leaving sorted by ID")
      items = items2
    end

    logger.info("item#get_sorted sorted #{items.length} items by #{sortby}");
    
    return items
  end
  
  def self.results_meta_breakdown(dialog,period,group,regmean=false)
    #-- Produce ranked item listings by meta categories of posters and raters, for the dialog results

    #-- Not sure why this wasn't set
    #@regmean = true

    start = Time.now

    dialog_id = dialog.class.to_s == 'Dialog' ? dialog.id : dialog.to_i
    period_id = period.class.to_s == 'Period' ? period.id : period.to_i
    group_id = group.class.to_s == 'Group' ? group.id : group.to_i

    #-- Criterion, if we're limiting by period
    ipwhere = (period_id > 0) ? "items.period_id=#{period_id}" : ""
    rpwhere = (period_id > 0) ? "ratings.period_id=#{period_id}" : ""

    #-- or by group
    igwhere = (group_id > 0) ? "items.group_id=#{group_id}" : ""
    rgwhere = (group_id > 0) ? "ratings.group_id=#{group_id}" : ""

    data = {}

    metamaps = Metamap.where(:id=>[3,5])

    #-- Find how many people and items for each metamap_node
    for metamap in metamaps

      metamap_id = metamap.id

      data[metamap.id] = {}
      data[metamap.id]['name'] = metamap.name
      data[metamap.id]['nodes'] = {}  # All nodes that have been used, for posting or rating, with their names
      data[metamap.id]['postedby'] = { # stats for what was posted by people in those meta categories
        'nodes' => {}
      }    
      data[metamap.id]['ratedby'] = {     # stats for what was rated by people in those meta categories
        'nodes' => {}
      }
      data[metamap.id]['matrix'] = {      # stats for posted by meta cats crossed by rated by metacats
        'post_rate' => {},
        'rate_post' => {}
      }
      data[metamap.id]['items'] = {}     # To keep track of the items marked with that meta cat
      data[metamap.id]['ratings'] = {}     # Keep track of the ratings of items in that meta cat

      #-- Everything posted, now leaving out metanode info
      #items = Item.where("items.dialog_id=#{dialog_id}").where(pwhere).where(gwhere).where("is_first_in_thread=1").joins(:participant=>{:metamap_node_participants=>:metamap_node}).includes(:item_rating_summary).where("metamap_node_participants.metamap_id=#{metamap_id}")
      #items = Item.where("items.dialog_id=#{dialog_id}").where(pwhere).where(gwhere).where("is_first_in_thread=1")
      #.joins(:participant)
      #.joins("join metamap_node_participants on (metamap_node_participants.metamap_id=#{metamap_id} and participants.id=metamap_node_participants.participant_id)")
      #.joins("join metamap_nodes on (metamap_nodes.id=metamap_node_participants.metamap_node_id and metamap_nodes.metamap_id=#{metamap_id})").includes(:item_rating_summary)
      items = Item.where("items.dialog_id=#{dialog_id}").where(ipwhere).where(igwhere).where("is_first_in_thread=1").joins(:participant).includes(:item_rating_summary)

      #-- Everything rated, now leaving out metanode info
      #ratings = Rating.where("ratings.dialog_id=#{dialog_id}").where(pwhere).where(gwhere).joins(:participant=>{:metamap_node_participants=>:metamap_node}).joins(:item=>:item_rating_summary).where("metamap_node_participants.metamap_id=#{metamap_id}")
      ratings = Rating.where("ratings.dialog_id=#{dialog_id}").where(rpwhere).where(rgwhere).joins(:participant).joins(:item=>:item_rating_summary)

      #-- Going through everything posted, group by meta node of poster
      itemlist = {}
      for item in items
        item_id = item.id
        
        metamap_node_participant = MetamapNodeParticipant.where(participant_id: item.posted_by, metamap_id: metamap_id).includes(:metamap_node).first
        next if not metamap_node_participant
        next if not metamap_node_participant.metamap_id == metamap_id
        next if not metamap_node_participant.metamap_node
        metamap_node_id = metamap_node_participant.metamap_node_id
        metamap_node_name = metamap_node_participant.metamap_node.name_as_group
        
        itemlist[item_id] = true
        poster_id = item.posted_by
        #metamap_node_id = item.participant.metamap_node_participants[0].metamap_node_id
        #metamap_node_name = item.participant.metamap_node_participants[0].metamap_node.name_as_group ? item.participant.metamap_node_participants[0].metamap_node.name_as_group : item.participant.metamap_node_participants[0].metamap_node.name

        data[metamap.id]['items'][item.id] = metamap_node_id

        logger.info("item#results_meta_breakdown item ##{item.id} poster meta:#{metamap_node_id}/#{metamap_node_name}") 

        if not data[metamap.id]['nodes'][metamap_node_id]
          #data[metamap.id]['nodes'][metamap_node_id] = metamap_node_name
          #data[metamap.id]['nodes'][metamap_node_id] = [metamap_node_name,item.participant.metamap_node_participants[0].metamap_node]
          data[metamap.id]['nodes'][metamap_node_id] = [metamap_node_name,metamap_node_participant.metamap_node]
          logger.info("item#results_meta_breakdown data[#{metamap.id}]['nodes'][#{metamap_node_id}] = #{metamap_node_name} id:#{data[metamap.id]['nodes'][metamap_node_id][1].id} (set from item)")
        end
        if not data[metamap.id]['postedby']['nodes'][metamap_node_id]
          data[metamap.id]['postedby']['nodes'][metamap_node_id] = {
            'name' => item.participant.metamap_node_participants[0].metamap_node.name,
            'items' => {},
            'itemsproc' => {},
            'posters' => {},
            'ratings' => {},
            'num_raters' => 0,
            'num_int_items' => 0,
            'num_app_items' => 0,
            'num_interest' => 0,
            'num_approval' => 0,
            'tot_interest' => 0,
            'tot_approval' => 0,
            'avg_votes_int' => 0,
            'avg_votes_app' => 0,
            'avg_interest' => 0,
            'avg_approval' => 0      
          }
        end
        if not data[metamap.id]['matrix']['post_rate'][metamap_node_id]
          data[metamap.id]['matrix']['post_rate'][metamap_node_id] = {}
        end
        data[metamap.id]['postedby']['nodes'][metamap_node_id]['items'][item_id] = item
        data[metamap.id]['postedby']['nodes'][metamap_node_id]['posters'][poster_id] = item.participant
      end

      #-- Going through everything rated, group by meta node of rater
      for rating in ratings
        rating_id = rating.id
        item_id = rating.item_id
        rater_id = rating.participant_id
        
        metamap_node_participant = MetamapNodeParticipant.where(participant_id: rater_id, metamap_id: metamap_id).includes(:metamap_node).first
        next if not metamap_node_participant
        next if not metamap_node_participant.metamap_id == metamap_id
        next if not metamap_node_participant.metamap_node
        metamap_node_id = metamap_node_participant.metamap_node_id
        metamap_node_name = metamap_node_participant.metamap_node.name_as_group
        
        #metamap_node_id = rating.participant.metamap_node_participants[0].metamap_node_id
        #metamap_node_name = rating.participant.metamap_node_participants[0].metamap_node.name_as_group ? rating.participant.metamap_node_participants[0].metamap_node.name_as_group : rating.participant.metamap_node_participants[0].metamap_node.name

        logger.info("item#results_meta_breakdown rating ##{rating_id} of item ##{item_id} rater meta:#{metamap_node_id}/#{metamap_node_name}") 

        # NB: Why did we do that?
        if not itemlist[item_id]
          logger.info("item#results_meta_breakdown item ##{item_id} doesn't exist. Skipping.")
          next
        end

        if not data[metamap.id]['nodes'][metamap_node_id]
          #data[metamap.id]['nodes'][metamap_node_id] = metamap_node_name
          data[metamap.id]['nodes'][metamap_node_id] = [metamap_node_name,metamap_node_participant.metamap_node]
          logger.info("item#results_meta_breakdown data[#{metamap.id}]['nodes'][#{metamap_node_id}] = #{metamap_node_name} id:#{data[metamap.id]['nodes'][metamap_node_id][1].id} (set from rating)")
        end
        data[metamap.id]['ratings'][rating.id] = metamap_node_id
        if not data[metamap.id]['ratedby']['nodes'][metamap_node_id]
          data[metamap.id]['ratedby']['nodes'][metamap_node_id] = {
            'name' => rating.participant.metamap_node_participants[0].metamap_node.name,
            'items' => {},
            'itemsproc' => {},
            'raters' => {},
            'ratings' => {},
            'num_raters' => 0,
            'num_int_items' => 0,
            'num_app_items' => 0,
            'num_interest' => 0,
            'num_approval' => 0,
            'tot_interest' => 0,
            'tot_approval' => 0,
            'avg_votes_int' => 0,
            'avg_votes_app' => 0,
            'avg_interest' => 0,
            'avg_approval' => 0      
          }
        end
        if not data[metamap.id]['matrix']['rate_post'][metamap_node_id]
          data[metamap.id]['matrix']['rate_post'][metamap_node_id] = {}
        end
        data[metamap.id]['ratedby']['nodes'][metamap_node_id]['items'][item_id] = rating.item
        data[metamap.id]['ratedby']['nodes'][metamap_node_id]['raters'][rater_id] = rating.participant
        data[metamap.id]['ratedby']['nodes'][metamap_node_id]['ratings'][rating_id] = rating
        item_metamap_node_id = data[metamap.id]['items'][item_id]

        if not data[metamap.id]['nodes'][item_metamap_node_id]
          logger.info("item#results_meta_breakdown data[#{metamap.id}]['nodes'][#{item_metamap_node_id}] doesn't exist. Skipping.")
          next
        end  

        data[metamap.id]['postedby']['nodes'][item_metamap_node_id]['ratings'][rating_id] = rating
        if not data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id]
          data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id] = {
            'post_name' => '',
            'rate_name' => '',
            'items' => {},
            'itemsproc' => {},
            'ratings' => {},
            'num_raters' => 0,
            'num_int_items' => 0,
            'num_app_items' => 0,
            'num_interest' => 0,
            'num_approval' => 0,
            'tot_interest' => 0,
            'tot_approval' => 0,
            'avg_votes_int' => 0,
            'avg_votes_app' => 0,
            'avg_interest' => 0,
            'avg_approval' => 0      
          }
        end
        #-- Store a matrix crossing the item's meta with the rater's meta (within a particular metamap, e.g. gender)
        data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id]['ratings'][rating_id] = rating
        data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id]['items'][item_id] = rating.item
        data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id]['post_name'] = data[metamap.id]['nodes'][item_metamap_node_id][0]
        data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][metamap_node_id]['rate_name'] = metamap_node_name
      end  # ratings

      #-- nodes_sorted moved from here

      #-- Adding up stats for postedby items. I.e. items posted by people in that meta.
      data[metamap.id]['postedby']['nodes'].each do |metamap_node_id,mdata|
        # {'num_items'=>0,'num_ratings'=>0,'avg_rating'=>0.0,'num_interest'=>0,'num_approval'=>0,'avg_appoval'=>0.0,'avg_interest'=>0.0,'avg_value'=>0,'value_winner'=>0}
        item_int_uniq = {}
        item_app_uniq = {}
        mdata['items'].each do |item_id,item|
          iproc = {'id'=>item.id,'name'=>show_name_in_result(item,dialog,period),'subject'=>item.subject,'votes'=>0,'num_raters'=>0,'num_interest'=>0,'tot_interest'=>0,'avg_interest'=>0.0,'num_approval'=>0,'tot_approval'=>0,'avg_approval'=>0.0,'value'=>0.0,'int_0_count'=>0,'int_1_count'=>0,'int_2_count'=>0,'int_3_count'=>0,'int_4_count'=>0,'app_n3_count'=>0,'app_n2_count'=>0,'app_n1_count'=>0,'app_0_count'=>0,'app_p1_count'=>0,'app_p2_count'=>0,'app_p3_count'=>0,'controversy'=>0,'ratings'=>[]}
          mdata['ratings'].each do |rating_id,rating|
            if rating.item_id == item.id
              iproc['votes'] += 1
              iproc['num_raters'] += 1
              if rating.interest
                iproc['num_interest'] += 1
                iproc['tot_interest'] += rating.interest
                iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
                case rating.interest.to_i
                when 0
                  iproc['int_0_count'] += 1
                when 1
                  iproc['int_1_count'] += 1
                when 2
                  iproc['int_2_count'] += 1
                when 3
                  iproc['int_3_count'] += 1
                when 4
                  iproc['int_4_count'] += 1
                end  
              end
              if rating.approval
                iproc['num_approval'] += 1
                iproc['tot_approval'] += rating.approval
                iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
                case rating.approval.to_i
                when -3
                  iproc['app_n3_count'] +=1   
                when -2
                  iproc['app_n2_count'] +=1   
                when -1
                  iproc['app_n1_count'] +=1   
                when 0
                  iproc['app_0_count'] +=1   
                when 1
                  iproc['app_p1_count'] +=1   
                when 2
                  iproc['app_p2_count'] +=1   
                when 3
                  iproc['app_p3_count'] +=1   
                end  
              end
              iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
              iproc['ratings'] << rating

              #-- Need this for regmean
              data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_raters'] += 1 if rating.interest or rating.approval
              data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_interest'] += 1 if rating.interest
              data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_approval'] += 1 if rating.approval
              data[metamap.id]['postedby']['nodes'][metamap_node_id]['tot_interest'] += rating.interest.to_i if rating.interest
              data[metamap.id]['postedby']['nodes'][metamap_node_id]['tot_approval'] += rating.approval.to_i if rating.approval
              item_int_uniq[item_id] = true if rating.interest
              item_app_uniq[item_id] = true if rating.approval

            end
          end
          iproc['controversy'] = (1.0 * ( iproc['app_n3_count'] * (-3.0 - iproc['avg_approval'])**2 + iproc['app_n2_count'] * (-2.0 - iproc['avg_approval'])**2 + iproc['app_n1_count'] * (-1.0 - iproc['avg_approval'])**2 + iproc['app_0_count'] * (0.0 - iproc['avg_approval'])**2 + iproc['app_p1_count'] * (1.0 - iproc['avg_approval'])**2 + iproc['app_p2_count'] * (2.0 - iproc['avg_approval'])**2 + iproc['app_p3_count'] * (3.0 - iproc['avg_approval'])**2 ) / iproc['num_approval']) if iproc['num_approval'] != 0
          data[metamap.id]['postedby']['nodes'][metamap_node_id]['itemsproc'][item_id] = iproc
        end

        data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_int_items'] = item_int_uniq.length
        data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_app_items'] = item_app_uniq.length
        data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_votes_int'] = ( data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_interest'] / data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_int_items'] ).to_i if data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_int_items'] > 0
        data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_votes_app'] = ( data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_approval'] / data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_app_items'] ).to_i if data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_app_items'] > 0
        data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_votes_int'] = 20 if data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_votes_int'] > 20
        data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_votes_app'] = 20 if data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_votes_app'] > 20
        data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_interest'] = 1.0 * data[metamap.id]['postedby']['nodes'][metamap_node_id]['tot_interest'] / data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_interest'] if data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_interest'] > 0
        data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_approval'] = 1.0 * data[metamap.id]['postedby']['nodes'][metamap_node_id]['tot_approval'] / data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_approval'] if data[metamap.id]['postedby']['nodes'][metamap_node_id]['num_approval'] > 0
        @avg_votes_int = data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_votes_int']
        @avg_votes_app = data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_votes_app']
        @avg_interest  = data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_interest']
        @avg_approval  = data[metamap.id]['postedby']['nodes'][metamap_node_id]['avg_approval']

        if regmean
          #-- Go through the items again and do a regression to the mean          
          mdata['items'].each do |item_id,item|
            iproc = data[metamap.id]['postedby']['nodes'][metamap_node_id]['itemsproc'][item_id]
            if iproc['num_interest'] < @avg_votes_int and iproc['num_interest'] > 0
              iproc['tot_interest'] += (@avg_votes_int - iproc['num_interest']) * @avg_interest
              iproc['num_interest'] = @avg_votes_int
              iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
            end  
            if iproc['num_approval'] < @avg_votes_app and iproc['num_approval'] > 0
              iproc['tot_approval'] += (@avg_votes_app - iproc['num_approval']) * @avg_approval
              iproc['num_approval'] = @avg_votes_app
              iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
            end  
            iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
            data[metamap.id]['postedby']['nodes'][metamap_node_id]['itemsproc'][item_id] = iproc
          end
        end
        #data[metamap.id]['postedby']['nodes'][metamap_node_id]['itemsproc'] = data[metamap.id]['postedby']['nodes'][metamap_node_id]['itemsproc'].sort {|a,b| b[1]['value']<=>a[1]['value']}
        data[metamap.id]['postedby']['nodes'][metamap_node_id]['itemsproc'] = data[metamap.id]['postedby']['nodes'][metamap_node_id]['itemsproc'].sort {|a,b| [b[1]['value'],b[1]['votes']]<=>[a[1]['value'],a[1]['votes']]}

      end

      #-- Adding up stats for ratedby items. I.e. items rated by people in that meta.
      data[metamap.id]['ratedby']['nodes'].each do |metamap_node_id,mdata|
        # {'num_items'=>0,'num_ratings'=>0,'avg_rating'=>0.0,'num_interest'=>0,'num_approval'=>0,'avg_appoval'=>0.0,'avg_interest'=>0.0,'avg_value'=>0,'value_winner'=>0}
        item_int_uniq = {}
        item_app_uniq = {}
        mdata['items'].each do |item_id,item|
          iproc = {'id'=>item.id,'name'=>show_name_in_result(item,@dialog,@period),'subject'=>item.subject,'votes'=>0,'num_raters'=>0,'num_interest'=>0,'tot_interest'=>0,'avg_interest'=>0.0,'num_approval'=>0,'tot_approval'=>0,'avg_approval'=>0.0,'value'=>0.0,'int_0_count'=>0,'int_1_count'=>0,'int_2_count'=>0,'int_3_count'=>0,'int_4_count'=>0,'app_n3_count'=>0,'app_n2_count'=>0,'app_n1_count'=>0,'app_0_count'=>0,'app_p1_count'=>0,'app_p2_count'=>0,'app_p3_count'=>0,'controversy'=>0,'ratings'=>[]}
          mdata['ratings'].each do |rating_id,rating|
            if rating.item_id == item.id
              iproc['votes'] += 1
              iproc['num_raters'] +=1
              if rating.interest
                iproc['num_interest'] += 1
                iproc['tot_interest'] += rating.interest.to_i
                iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
                case rating.interest.to_i
                when 0
                  iproc['int_0_count'] += 1
                when 1
                  iproc['int_1_count'] += 1
                when 2
                  iproc['int_2_count'] += 1
                when 3
                  iproc['int_3_count'] += 1
                when 4
                  iproc['int_4_count'] += 1
                end  
              end
              if rating.approval
                iproc['num_approval'] += 1
                iproc['tot_approval'] += rating.approval.to_i
                iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
                case rating.approval.to_i
                when -3
                  iproc['app_n3_count'] +=1   
                when -2
                  iproc['app_n2_count'] +=1   
                when -1
                  iproc['app_n1_count'] +=1   
                when 0
                  iproc['app_0_count'] +=1   
                when 1
                  iproc['app_p1_count'] +=1   
                when 2
                  iproc['app_p2_count'] +=1   
                when 3
                  iproc['app_p3_count'] +=1   
                end  
              end
              iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
              iproc['ratings'] << rating

              #-- Need this for regmean
              data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_raters'] += 1 if rating.interest or rating.approval
              data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_interest'] += 1 if rating.interest
              data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_approval'] += 1 if rating.approval
              data[metamap.id]['ratedby']['nodes'][metamap_node_id]['tot_interest'] += rating.interest.to_i if rating.interest
              data[metamap.id]['ratedby']['nodes'][metamap_node_id]['tot_approval'] += rating.approval.to_i if rating.approval
              item_int_uniq[item_id] = true if rating.interest
              item_app_uniq[item_id] = true if rating.approval

            end
          end
          iproc['controversy'] = (1.0 * ( iproc['app_n3_count'] * (-3.0 - iproc['avg_approval'])**2 + iproc['app_n2_count'] * (-2.0 - iproc['avg_approval'])**2 + iproc['app_n1_count'] * (-1.0 - iproc['avg_approval'])**2 + iproc['app_0_count'] * (0.0 - iproc['avg_approval'])**2 + iproc['app_p1_count'] * (1.0 - iproc['avg_approval'])**2 + iproc['app_p2_count'] * (2.0 - iproc['avg_approval'])**2 + iproc['app_p3_count'] * (3.0 - iproc['avg_approval'])**2 ) / iproc['num_approval']) if iproc['num_approval'] != 0
          data[metamap.id]['ratedby']['nodes'][metamap_node_id]['itemsproc'][item_id] = iproc
        end    

        data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_int_items'] = item_int_uniq.length
        data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_app_items'] = item_app_uniq.length
        data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_votes_int'] = ( data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_interest'] / data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_int_items'] ).to_i if data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_int_items'] > 0
        data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_votes_app'] = ( data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_approval'] / data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_app_items'] ).to_i if data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_app_items'] > 0
        data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_votes_int'] = 20 if data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_votes_int'] > 20
        data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_votes_app'] = 20 if data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_votes_app'] > 20
        data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_interest'] = 1.0 * data[metamap.id]['ratedby']['nodes'][metamap_node_id]['tot_interest'] / data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_interest'] if data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_interest'] > 0
        data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_approval'] = 1.0 * data[metamap.id]['ratedby']['nodes'][metamap_node_id]['tot_approval'] / data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_approval'] if data[metamap.id]['ratedby']['nodes'][metamap_node_id]['num_approval'] > 0
        @avg_votes_int = data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_votes_int']
        @avg_votes_app = data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_votes_app']
        @avg_interest  = data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_interest']
        @avg_approval  = data[metamap.id]['ratedby']['nodes'][metamap_node_id]['avg_approval']

        if regmean
          #-- Go through the items again and do a regression to the mean
          mdata['items'].each do |item_id,item|
            iproc = data[metamap.id]['ratedby']['nodes'][metamap_node_id]['itemsproc'][item_id]
            if iproc['num_interest'] < @avg_votes_int and iproc['num_interest'] > 0
              iproc['tot_interest'] += (@avg_votes_int - iproc['num_interest']) * @avg_interest
              iproc['num_interest'] = @avg_votes_int
              iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
            end  
            if iproc['num_approval'] < @avg_votes_app and iproc['num_approval'] > 0
              iproc['tot_approval'] += (@avg_votes_app - iproc['num_approval']) * @avg_approval
              iproc['num_approval'] = @avg_votes_app
              iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
            end  
            iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
            data[metamap.id]['ratedby']['nodes'][metamap_node_id]['itemsproc'][item_id] = iproc
          end
        end
        data[metamap.id]['ratedby']['nodes'][metamap_node_id]['itemsproc'] = data[metamap.id]['ratedby']['nodes'][metamap_node_id]['itemsproc'].sort {|a,b| [b[1]['value'],b[1]['votes']]<=>[a[1]['value'],a[1]['votes']]}
      end

      #-- Adding up matrix stats
      data[metamap.id]['matrix']['post_rate'].each do |item_metamap_node_id,rdata|
        #-- Going through all metas with items that have been rated
        rdata.each do |rate_metamap_node_id,mdata|
          #-- Going through all the metas that have rated items in that meta (all within a particular metamap, like gender)
          item_int_uniq = {}
          item_app_uniq = {}
          mdata['items'].each do |item_id,item|
            #-- Going through the items of the second meta that have rated the first meta
            iproc = {'id'=>item.id,'name'=>show_name_in_result(item,@dialog,@period),'subject'=>item.subject,'votes'=>0,'num_interest'=>0,'tot_interest'=>0,'avg_interest'=>0.0,'num_approval'=>0,'tot_approval'=>0,'avg_approval'=>0.0,'value'=>0.0,'int_0_count'=>0,'int_1_count'=>0,'int_2_count'=>0,'int_3_count'=>0,'int_4_count'=>0,'app_n3_count'=>0,'app_n2_count'=>0,'app_n1_count'=>0,'app_0_count'=>0,'app_p1_count'=>0,'app_p2_count'=>0,'app_p3_count'=>0,'controversy'=>0,'rateapproval'=>0,'rateinterest'=>0,'num_raters'=>0,'ratings'=>[]}
            mdata['ratings'].each do |rating_id,rating|
              if rating.item_id == item.id
                iproc['votes'] += 1
                if rating.interest
                  iproc['num_interest'] += 1
                  iproc['tot_interest'] += rating.interest.to_i
                  iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
                  case rating.interest.to_i
                  when 0
                    iproc['int_0_count'] += 1
                  when 1
                    iproc['int_1_count'] += 1
                  when 2
                    iproc['int_2_count'] += 1
                  when 3
                    iproc['int_3_count'] += 1
                  when 4
                    iproc['int_4_count'] += 1
                  end  
                end
                if rating.approval                
                  iproc['num_approval'] += 1
                  iproc['tot_approval'] += rating.approval.to_i
                  iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
                  case rating.approval.to_i
                  when -3
                    iproc['app_n3_count'] +=1   
                  when -2
                    iproc['app_n2_count'] +=1   
                  when -1
                    iproc['app_n1_count'] +=1   
                  when 0
                    iproc['app_0_count'] +=1   
                  when 1
                    iproc['app_p1_count'] +=1   
                  when 2
                    iproc['app_p2_count'] +=1   
                  when 3
                    iproc['app_p3_count'] +=1   
                  end  
                end
                iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
                iproc['num_raters'] += 1
                iproc['ratingnoregmean'] = "Average interest: #{iproc['tot_interest']} total / #{iproc['num_interest']} ratings = #{iproc['avg_interest']}<br>" + "Average approval: #{iproc['tot_approval']} total / #{iproc['num_approval']} ratings = #{iproc['avg_approval']}<br>" + "Value: #{iproc['avg_interest']} interest * #{iproc['avg_approval']} approval = #{iproc['value']}"
                iproc['ratings'] << rating

                #-- Need this for regmean
                data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_raters'] += 1 if rating.interest or rating.approval
                data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_interest'] += 1 if rating.interest
                data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_approval'] += 1 if rating.approval
                data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['tot_interest'] += rating.interest.to_i if rating.interest
                data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['tot_approval'] += rating.approval.to_i if rating.approval
                item_int_uniq[item_id] = true if rating.interest
                item_app_uniq[item_id] = true if rating.approval

              end
            end
            iproc['controversy'] = (1.0 * ( iproc['app_n3_count'] * (-3.0 - iproc['avg_approval'])**2 + iproc['app_n2_count'] * (-2.0 - iproc['avg_approval'])**2 + iproc['app_n1_count'] * (-1.0 - iproc['avg_approval'])**2 + iproc['app_0_count'] * (0.0 - iproc['avg_approval'])**2 + iproc['app_p1_count'] * (1.0 - iproc['avg_approval'])**2 + iproc['app_p2_count'] * (2.0 - iproc['avg_approval'])**2 + iproc['app_p3_count'] * (3.0 - iproc['avg_approval'])**2 ) / iproc['num_approval']) if iproc['num_approval'] != 0
            data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['itemsproc'][item_id] = iproc
          end

          data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_int_items'] = item_int_uniq.length
          data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_app_items'] = item_app_uniq.length
          data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_votes_int'] = ( data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_interest'] / data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_int_items'] ).to_i if data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_int_items'] > 0
          data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_votes_app'] = ( data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_approval'] / data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_app_items'] ).to_i if data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_app_items'] > 0
          data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_votes_int'] = 20 if data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_votes_int'] > 20
          data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_votes_app'] = 20 if data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_votes_app'] > 20
          data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_interest'] = 1.0 * data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['tot_interest'] / data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_interest'] if data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_interest'] > 0
          data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_approval'] = 1.0 * data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['tot_approval'] / data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_approval'] if data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_approval'] > 0
          @avg_votes_int = data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_votes_int']
          @avg_votes_app = data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_votes_app']
          @avg_interest  = data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_interest']
          @avg_approval  = data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['avg_approval']
          if metamap.id == 3
            #logger.info("dialogs#result data[#{metamap.id}]['matrix']['post_rate'][#{item_metamap_node_id}][#{rate_metamap_node_id}]: #{data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id].inspect}")
            logger.info("dialogs#result gender (3) matrix posted by #{item_metamap_node_id} rated by #{rate_metamap_node_id} num_interest:#{data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_interest']} / num_int_items:#{item_int_uniq.length} =  avg_votes_int:#{@avg_votes_int}, num_approval:#{data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['num_approval']} / num_app_items:#{item_app_uniq.length}  = avg_votes_app:#{@avg_votes_app} avg_interest:#{@avg_interest} avg_approval:#{@avg_approval}")
          end

          if regmean
            #-- Go through the items again and do a regression to the mean
            mdata['items'].each do |item_id,item|
              iproc = data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['itemsproc'][item_id]
              iproc['ratingwithregmean'] = ''
              if iproc['num_interest'] < @avg_votes_int and iproc['num_interest'] > 0
                old_num_interest = iproc['num_interest']
                old_tot_interest = iproc['tot_interest']
                iproc['tot_interest'] += (@avg_votes_int - iproc['num_interest']) * @avg_interest
                iproc['num_interest'] = @avg_votes_int
                iproc['avg_interest'] = 1.0 * iproc['tot_interest'] / iproc['num_interest']
                iproc['ratingwithregmean'] += "int votes adjusted #{old_num_interest} -> #{iproc['num_interest']}. int total adjusted #{old_tot_interest} -> #{iproc['tot_interest']}<br>"
              end  
              if iproc['num_approval'] < @avg_votes_app and iproc['num_approval'] > 0
                old_num_approval = iproc['num_approval']
                old_tot_approval = iproc['tot_approval']
                iproc['tot_approval'] += (@avg_votes_app - iproc['num_approval']) * @avg_approval
                iproc['num_approval'] = @avg_votes_app
                iproc['avg_approval'] = 1.0 * iproc['tot_approval'] / iproc['num_approval']
                iproc['ratingwithregmean'] += "app votes adjusted #{old_num_approval} -> #{iproc['num_approval']}. app total adjusted #{old_tot_approval} -> #{iproc['tot_approval']}<br>"
              end  
              iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
              iproc['ratingwithregmean'] += "Average interest: #{iproc['tot_interest']} total / #{iproc['num_interest']} ratings = #{iproc['avg_interest']}<br>" + "Average approval: #{iproc['tot_approval']} total / #{iproc['num_approval']} ratings = #{iproc['avg_approval']}<br>" + "Value: #{iproc['avg_interest']} interest * #{iproc['avg_approval']} approval = #{iproc['value']}"
              data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['itemsproc'][item_id] = iproc
            end
          end
          data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['itemsproc'] = data[metamap.id]['matrix']['post_rate'][item_metamap_node_id][rate_metamap_node_id]['itemsproc'].sort {|a,b| [b[1]['value'],b[1]['votes']]<=>[a[1]['value'],a[1]['votes']]}

        end
      end

      if ((@short_full == 'gender' and metamap.id == 3) or (@short_full == 'age' and metamap.id == 5))
        #-- We'd want nodes in order of value of the top item. Hm, that's tricky
      	for metamap_node_id,minfo in data[metamap.id]['nodes']
      		metamap_node_name = minfo[0]
      		metamap_node = minfo[1]
      		data[metamap.id]['nodes'][metamap_node_id][2] = 0
          if data[metamap.id]['postedby']['nodes'][metamap_node_id] and  data[metamap.id]['postedby']['nodes'][metamap_node_id]['items'].length > 0
      			if data[metamap.id]['matrix']['post_rate'][metamap_node_id].length > 0
        			for rate_metamap_node_id,rdata in data[metamap.id]['matrix']['post_rate'][metamap_node_id]
        			  if rate_metamap_node_id == metamap_node_id
          				for item_id,i in data[metamap.id]['matrix']['post_rate'][metamap_node_id][rate_metamap_node_id]['itemsproc']
          					item = data[0]['items'][item_id]
                    iproc = data[0]['itemsproc'][item_id]
                    #-- It should really be by iproc['value'] but somehow that doesn't work.
                    data[metamap.id]['nodes'][metamap_node_id][2] = item['value']
                		break
                  end
                end
              end
            end
          end
        end        
        # sort priority order: value, sort order, id    
        #data[metamap.id]['nodes_sorted'] = data[metamap.id]['nodes'].sort {|a,b| [b[1][2],a[1][1].sortorder,a[1][0]]<=>[a[1][2],b[1][1].sortorder,b[1][0]]}
        data[metamap.id]['nodes_sorted'] = data[metamap.id]['nodes'].sort {|b,a| [a[1][2],a[1][1].sortorder.to_s,a[1][0]]<=>[b[1][2],b[1][1].sortorder.to_s,b[1][0]]}
      else
        #-- Put nodes in sorting order and/or alphabetical order
        #data[metamap.id]['nodes_sorted'] = data[metamap.id]['nodes'].sort {|a,b| a[1]<=>b[1]}
        data[metamap.id]['nodes_sorted'] = data[metamap.id]['nodes'].sort {|b,a| [a[1][1].sortorder.to_s,a[1][0]]<=>[b[1][1].sortorder.to_s,b[1][0]]}
      end

    end # metamaps
    
    duration = (Time.now - start) * 1000
    logger.info("item#results_meta_breakdown elapsed time: #{duration} milliseconds")
    
    return data
      
  end  
  
  def self.show_name_in_result(item,dialog,period)
    #-- The participants name in results. Don't show it if the settings say so
		if dialog and dialog.current_period.to_i > 0 and item.period_id==dialog.current_period and not dialog.settings_with_period["names_visible_voting"]
		  #-- Item is in the current period and it says to now show it
			"[name withheld during decision period]"
		elsif period and not period.names_visible_general
			"[name withheld for this decision period]"
		elsif dialog and not dialog.names_visible_general
			"[name withheld for this discussion]"
		else
			"<a href=\"/participant/#{item.id}/profile\">" + ( item.participant ? item.participant.name : item.posted_by ) + "</a>"
		end
  end  

  def self.custom_item_sort(items, itemsproc, participant_id, dialog, want_crosstalk='')
    #-- Create the default sort for items in a discussion:
    #-- current user's own item first
    #-- items he hasn't yet rated, alternating:
    #-- - from own gender (or age)
    #-- - from other genders (or ages)
    #-- already rated items

    if want_crosstalk == 'age'
      metamap_id = 5
      logger.info("item#custom_item_sort according to age (got:#{want_crosstalk})")
    else
      metamap_id = 3
      logger.info("item#custom_item_sort according to gender (got:#{want_crosstalk})")
    end
    sort2 = 'date'

    if dialog and dialog.active_period
      metamap_id = dialog.active_period.sort_metamap_id if dialog.active_period.sort_metamap_id.to_i > 0
      sort2 = dialog.active_period.sort_order if dialog.active_period.sort_order.to_s != ''
    end
    
    if sort2 == 'value'
      sort2key = 'items.value desc'
      asort2key = 'value'
    elsif sort2 == 'date'
      sort2key = 'items.id desc'
      asort2key = 'id'
    else
      sort2key = 'items.id desc'
      asort2key = 'id'
    end  
    
    #-- Sort by the secondary key first, so they're in that order already before putting them into different piles
    if items.class == Array
      items.sort! { |a,b| b.send(asort2key) <=> a.send(asort2key) }
    else  
      items = items.order(sort2key)
    end
    
    mnps = MetamapNodeParticipant.where(:metamap_id=>metamap_id).where(:participant_id=>participant_id)
    if mnps.length > 0
      own_node_id = mnps[0].metamap_node_id
    else
      own_node_id = 0  
    end
    
    own_items = []
    own_cat = []
    other_cat = []
    rated = []
    
    xorder = 0
    
    #-- Let's go through them and put them in different piles: own_items, rated, own_cat, other_cat
    for item in items
      #xitem = item.clone
      if dialog and dialog.current_period.to_i > 0 and item.period_id.to_i != dialog.current_period.to_i
        #-- Only include items from current period
        next
      end      
      if item.posted_by == participant_id
        xorder += 1
        item.explanation = "##{xorder}: own item" if item['explanation']
        own_items << item
        #elsif item['rateapproval'].to_i > 0 and item['rateinterest'].to_i > 0
      elsif itemsproc[item.id]['hasrating'].to_i > 0
        #logger.info("item#custom_item_sort rated item")
        rated << item
      else
        xcat = -1
        if item.participant and item.participant.metamap_node_participants
          for mnp in item.participant.metamap_node_participants
            if mnp.metamap_id == metamap_id
              xcat = mnp.metamap_node_id
              break
            end
          end
        end        
        if xcat == own_node_id
          own_cat << item
        else
          other_cat << item
        end
      end
    end

    logger.info("item#custom_item_sort own_items:#{own_items.length} own_cat:#{own_cat.length} other_cat:#{other_cat.length} rated:#{rated.length}")
    
    #-- Sort the rated items in descending value order
    rated.sort! {|a,b| [b['value'],b['votes'],b['id']]<=>[a['value'],a['votes'],a['id']]}
    
    # Own items go first
    newitems = own_items
    
    gotown = 0
    gotother = 0
    gotrated = 0
    
    isdone = false
    
    #-- Mix the remaining unrated ones together, followed by the rated
    while not isdone
      if gotother < other_cat.length or gotown < own_cat.length
        if gotother < other_cat.length
          item = other_cat[gotother]
          xcat = '???'
          for mnp in item.participant.metamap_node_participants
            if mnp.metamap_id == metamap_id
              xcat = mnp.metamap_node.name
              break
            end
          end
          xorder += 1
          item.explanation = "##{xorder}: other cat (#{xcat})" if item['explanation']
          logger.info("item#custom_item_sort item #{item.id} ##{xorder}: other cat (#{xcat})")
          newitems << item
          gotother += 1
        end
        if gotown < own_cat.length
          item = own_cat[gotown]
          xcat = '???'
          for mnp in item.participant.metamap_node_participants
            if mnp.metamap_id == metamap_id
              xcat = mnp.metamap_node.name
              break
            end
          end
          xorder += 1
          item.explanation = "##{xorder}: own cat (#{xcat})" if item['explanation']
          logger.info("item#custom_item_sort item #{item.id} ##{xorder}: own cat (#{xcat})")
          newitems << item
          gotown += 1
        end
      elsif gotrated < rated.length
        item = rated[gotrated]
        xorder += 1
        item.explanation = "##{xorder}: previously rated" if item['explanation']        
        logger.info("item#custom_item_sort item #{item.id} ##{xorder}: previously rated")
        newitems << item
        gotrated += 1
      else
        isdone = true
        break
      end  
    end
    
    #-- Now paginate
    #first = (page - 1) * perscr
    #if first + perscr <= newitems.length
    #  last = first + perscr - 1
    #else
    #  last = newitems.length - 1
    #end

    #logger.info("item#custom_item_sort paginating: #{first} -  #{last}")
        
    #outitems = []
    #for inum in (first..last).to_a
    #  outitems << newitems[inum]
    #end
  
    #outitems
  
    newitems
  end
   
  def self.custom_item_sort_OLD(items, page, perscr, participant_id)
    #-- Create the default sort for items:
    #-- current user's own item first
    #-- items he hasn't yet rated, alternating:
    #-- - from own country
    #-- - from other countries
    #-- already rated items
    
    metamap_id = 4
    
    mnps = MetamapNodeParticipant.where(:metamap_id=>metamap_id).where(:participant_id=>participant_id)
    if mnps.length > 0
      own_node_id = mnps[0].metamap_node_id
    else
      own_node_id = 0  
    end
    
    own_items = []
    own_country = []
    other_country = []
    rated = []
    
    xorder = 0
    
    #-- Let's go through them and put them in different piles
    for item in items
      #xitem = item.clone
      if item.posted_by == participant_id
        xorder += 1
        item.explanation = "##{xorder}: own item" if item['explanation']
        own_items << item
      elsif item['hasrating'].to_i > 0 or item['rateapproval'] or item['rateinterest']
        rated << item
      else
        xcountry = -1
        if item.participant and item.participant.metamap_node_participants
          for mnp in item.participant.metamap_node_participants
            if mnp.metamap_id == metamap_id
              xcountry = mnp.metamap_node_id
              break
            end
          end
        end        
        if xcountry == own_node_id
          own_country << item
        else
          other_country << item
        end
      end
    end

    logger.info("item#custom_item_sort own_items:#{own_items.length} own_country:#{own_country.length} other_country:#{other_country.length} rated:#{rated.length}")
    
    newitems = own_items
    
    gotown = 0
    gotother = 0
    gotrated = 0
    
    isdone = false
    
    #-- Mix them together
    while not isdone
      if gotother < other_country.length or gotown < own_country.length
        if gotother < other_country.length
          item = other_country[gotother]
          xcountry = '???'
          for mnp in item.participant.metamap_node_participants
            if mnp.metamap_id == metamap_id
              xcountry = mnp.metamap_node.name
              break
            end
          end
          xorder += 1
          item.explanation = "##{xorder}: other country (#{xcountry})" if item['explanation']
          newitems << item
          gotother += 1
        end
        if gotown < own_country.length
          item = own_country[gotown]
          xcountry = '???'
          for mnp in item.participant.metamap_node_participants
            if mnp.metamap_id == metamap_id
              xcountry = mnp.metamap_node.name
              break
            end
          end
          xorder += 1
          item.explanation = "##{xorder}: own country (#{xcountry})" if item['explanation']
          newitems << item
          gotown += 1
        end
      elsif gotrated < rated.length
        item = rated[gotrated]
        xorder += 1
        item.explanation = "##{xorder}: previously rated (#{item.rateinterest}/#{item.rateapproval})" if item['explanation']        
        newitems << item
        gotrated += 1
      else
        isdone = true
        break
      end  
    end
    
    #-- Now paginate
    first = (page - 1) * perscr
    if first + perscr <= newitems.length
      last = first + perscr - 1
    else
      last = newitems.length - 1
    end

    logger.info("item#custom_item_sort paginating: #{first} -  #{last}")
        
    outitems = []
    for inum in (first..last).to_a
      outitems << newitems[inum]
    end
  
    outitems
  end
   
  def voting_ok(participant_id)  
    #-- Decide whether the current user is allowed to rate the current item
    #-- They need to be a member of the group or discussion
    #-- The main reason should either be that voting manually is turned off, or voting period is over, and they already rated it
    
    #-- Not sure if we need any of this any longer. Currently using reply_ok to serve the same function in most places
    return true
    
    if self.v_p_id and v_p_id == participant_id
      #-- If we're called again for the same user, just return the stored result
      return self.v_ok
    end
    ok = true
    exp = ''
    if participant_id.to_i == 0
      ok = false  
      exp = "Your account isn't recognized"    
    elsif self.dialog
      #-- The message is for a discussion
      #-- Is he a member of a group that's a member of the discussion?
      is_in_discussion = false;
      groupsin = GroupParticipant.where("participant_id=#{participant_id}").includes(:group)       
      dialoggroupsin = []
      for group1 in dialog.groups
        for group2 in groupsin
          if group2.group and group1 and group2.group.id == group1.id
            #-- He's a member of one of those groups, so it is ok
            is_in_discussion = true
            break
          end
        end
        break if is_in_discussion
      end

      if self.period_id.to_i > 0
        period = Period.find_by_id(self.period_id)
      end
      
      #-- Even if they're in the discussion, they can't vote if voting manually is turned off, or voting period is over, and they already rated it      
      if not is_in_discussion
        ok = false
        exp = "You're not in a group that participates in this discussion"
      elsif not self.dialog.voting_open
        ok = false
        exp = "Ratings are not open for this discussion"
      elsif self.period_id.to_i > 0 and not period
        ok = false
        exp = "The decision period doesn't seem to exist"
      elsif period and period.endrating.to_s != '' and Time.now.strftime("%Y-%m-%d") > period.endrating.strftime("%Y-%m-%d") and self.is_first_in_thread
        #-- The rating in the period is over, and this is a root item
        ok = false
        exp = "The decision period is closed"
      elsif period and period.endrating.to_s != '' and Time.now.strftime("%Y-%m-%d") > period.endrating.strftime("%Y-%m-%d") and self['hasrating'].to_i > 0
        #-- The rating in the period is over, and this person rated the item
        #logger.info("item#voting_ok #{self.id} already rated and period #{self.period_id} is over (#{Time.now.strftime("%Y-%m-%d")} > #{period.endrating})")
        ok = false
        exp = "Your vote from this decision period is frozen"        
      else
        ok = true
        exp = "Has discussion, but no reason to not allow vote"
      end

    elsif self.group_id.to_i > 0  
      #-- This message belongs to a group
      #-- Is the user a member of it?
      group = self.group ? self.group : Group.find_by_id(self.group_id)
      group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",self.group_id,participant_id).first
      if not group_participant
        #-- He's not a member
        #logger.info("item#voting_ok #{participant_id} is not a member of the group #{self.group_id} for item #{self.id}")
        ok = false
        exp = "You are not a member of this group"
      else
        exp = "Is a group member. All ok."  
      end

    else
      ok = true
      exp = "Didn't match any of the criteria"
      
    end
    
    self.v_ok = ok
    self.v_ok_exp = exp
    self.v_p_id = participant_id
    
    #logger.info("item#voting_ok ##{self.id} ok:#{ok} exp:#{exp}")
    
    ok
  end  
  
  def voting_ok_exp(participant_id=nil)
    if self.v_p_id and (not participant_id or v_p_id == participant_id)
      #-- If we're called again for the same user, just return the stored result
    else
      #-- If this is the first time, figure it out first
      voting_ok(participant_id)  
    end
    return self.v_ok_exp    
  end  
  
  #def hasrating
  #  #-- Normally this is part of the query done, but in case it isn't let's look it up
  #  rating = Rating.where("item_id=#{self.id} and ratings.participant_id=#{current_participant.id}")
  #  rating.participant_id
  #end 
  
  def num_in_thread
    #-- How many items are there in the whole thread for this item
    first = self.first_in_thread.to_i
    first = self.id if first == 0 and self.is_first_in_thread
    if first > 0
      Item.where(:first_in_thread=>first).count
    else  
      0
    end  
  end 
  
  def num_replies(conversation_id=0)
    #-- How many replies does this item have?
    if conversation_id > 0
      Item.where(conversation_id: conversation_id, reply_to: self.id).count
    else
      Item.where(reply_to: self.id).count
    end
  end
  
  def reply_ok(participant_id)
    #-- Decide whether the current user is allowed to reply on this item
    #(@from == 'dialog' and item.dialog and item.dialog.settings_with_period["allow_replies"] and session[:group_is_member]) or (@from == 'group' and item.group and @is_member)

    if participant_id.to_i == 0
      return false
      
    elsif participant_id == self.posted_by
      # It's the author
      return true  
      
    elsif false and self.intra_conv != 'public' and self.conversation_id.to_i > 0
      # A conversation-only post can only be commented on by members of the communities in the conversation
      # In the apart phase, furthermore only members of one of the communities of the poster can reply/vote
      if @conversation and @conversation.together_apart != 'apart' and defined? @in_conversation 
        return @in_converation
      end

      participant = Participant.find_by_id(participant_id)
      conversation = Conversation.find_by_id(self.conversation_id)
      if conversation
        if conversation.together_apart == 'apart'
          # One must be in the community of the poster
          for com in conversation.communities
            if participant.tag_list_downcase.include?(com.tagname) and self.participant.tag_list_downcase.include?(com.tagname)
              return true
            end
          end
        else
          for com in conversation.communities
            if participant.tag_list_downcase.include?(com.tagname)
              return true
            end
          end
        end
      end
      return false
      
    elsif false and self.dialog_id.to_i > 0
      #-- This item belongs to a discussion
      
      dialog = Dialog.includes(:groups).find_by_id(self.dialog_id)
      if not dialog.settings_with_period["allow_replies"]
        #-- Nobody's allowed to reply in that discussion
        return false
      end

      #-- Is he a member of a group that's a member of the discussion?
      groupsin = GroupParticipant.where("participant_id=#{participant_id}").includes(:group)       
      dialoggroupsin = []
      for group1 in dialog.groups
        for group2 in groupsin
          if group2.group and group1 and group2.group.id == group1.id
            #-- He's a member of one of those groups, so it is ok
            return true
          end
        end
      end
      return false
      
    elsif self.group_id.to_i > 0  
      #-- This message belongs to a grop
      group = Group.includes(:owner_participant).find_by_id(self.group_id)
      group_participant = GroupParticipant.where("group_id = ? and participant_id = ?",self.group_id,participant_id).first
      if group_participant
        #-- He's a member
        return true
      else  
        return false
      end
    end
    
    #-- If the item is not in a discussion or group, then anybody can reply. Probably not true, but let's pretend that for now
    return true

  end
    
  def show_subgroup
    ( self.subgroup_list - ['none'] ).join(', ')
  end   
  
  def show_subgroup_with_link(link)
    #-- Show a subgroup list with links. Construct link tag from url, ending in =
    ( self.subgroup_list - ['none'] ).collect{|tag| "<a href=\"#{link}#{tag}\">#{tag}</a>"}.join(', ')
  end   

  def show_tag_list(with_links=false,show_result=false)
    xlist = ''
    tags.each do |tag|
      xlist += ', ' if xlist != ''
      xlist += '#'
      if with_links
        url = "/dialogs/#{VOH_DISCUSSION_ID}/slider?messtag=#{tag.name}"
        if show_result
          url += "&show_result=1"
        end
        xlist += "<a href=\"#{url}\">" + tag.name + "</a>"
      else
        xlist += tag.name
      end 
    end
    xlist
  end
  
  def get_preview
    #-- If there's any info from link_thumbnailer, or similar, construct a preview to show as a thumbnail
    if self.oembed_response and self.oembed_response.has_key?(:img)
      linkurl = self.oembed_response[:url]
      linkimg = self.oembed_response[:img]
      linktitle = self.oembed_response[:title]
      description = self.oembed_response[:description]
      if linkimg.to_s == ''
        return ''
      else
        ximg = "<a href=\"#{linkurl}\" target=\"_blank\"><img src=\"#{linkimg}\" width=\"140\" style=\"width:150px\" title=\"#{description}\"></a>"
        xhtml = "<div style=\"text-align:center;font-size:10px\">#{ximg}<br>#{linktitle}</div>"
      end
      return xhtml
    else
      return('')
    end  
  end
      
end
