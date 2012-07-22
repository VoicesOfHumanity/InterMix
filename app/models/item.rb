class Item < ActiveRecord::Base
  belongs_to :participant, :counter_cache => true, :foreign_key => :posted_by
  belongs_to :moderatedparticipant, :class_name => "Participant", :foreign_key => :moderated_by
  belongs_to :group, :counter_cache => true
  belongs_to :dialog
  belongs_to :period
  has_many :allratings, :class_name=>"Rating"
  has_one :item_rating_summary
  serialize :oembed_response
  
  acts_as_taggable
  
  after_create :process_new_item
  
  def self.tags
    tag_counts.collect {|t| t.name}.join(', ')  
  end
  
  def add_image(tempfilepath)
    #-- Handle an image that has been uploaded
    @picdir = "#{DATADIR}/items/#{self.id}"
    `mkdir "#{@picdir}"` if not File.exist?(@picdir)
    @bigfilepath = "#{@picdir}/big.jpg"
    @thumbfilepath = "#{@picdir}/thumb.jpg"

    p = Magick::Image.read("#{tempfilepath}").first
    if p
      p.change_geometry('640x640') { |cols, rows, img| img.resize!(cols, rows) }
      p.write("#{@bigfilepath}")
    end
    
    logger.info("item#add_image converting #{tempfilepath} to #{@bigfilepath}")         

    if p and File.exist?(@bigfilepath)

  		bigpicsize = File.stat("#{@bigfilepath}").size
      iwidth = iheight = 0
      begin
        open("#{@bigfilepath}", "rb") do |fh|
          iwidth,iheight = ImageSize.new(fh.read).get_size
        end
      rescue
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
    create_xml
    if old_message_id.to_i == 0
      #-- Only twitter and e-mail if it really is a new message just being posted
      personal_twitter
      emailit
    end
    self.save
  end  
  
  def emailit
    #-- E-mail this item to everybody who's allowed to see it, and who's configured to receive it
    #-- Group items are only available to group members. Other items are available to everybody
    #-- Each person might be configured to receive e-mails or not 

    participants = []
    if self.group_id.to_i > 0
      logger.info("Item#emailit e-mailing members of group ##{self.group_id}")
      group = Group.includes(:participants).find_by_id(self.group_id)
      participants = group.participants if group
    else
      #logger.info("Item#emailit e-mailing forum message to everybody")
      #participants = Participant.where("(status='active' or status is null) and forum_email='instant'").all
    end    
    logger.info("Item#emailit #{participants.length} people to distribute to")

    #-- Distribute to members of the target group
    for recipient in participants
      if recipient.no_email
        logger.info("#{recipient.id}:#{recipient.name} is blocking all email, so skipping")
        next        
      elsif recipient.status != 'active'
        logger.info("#{recipient.id}:#{recipient.name} is not active, so skipping")
        next
      elsif group and not (recipient.group_email=='instant' or recipient.forum_email=='instant')
        logger.info("#{recipient.id}:#{recipient.name} is not set for instant group mail, so skipping")
        next
      elsif not group and not recipient.forum_email=='instant'
        logger.info("#{recipient.id}:#{recipient.name} is not set for instant forum mail, so skipping")
        next
      end  
      if recipient.email.to_s == ''
        logger.info("#{recipient.id}:#{recipient.name} has no e-mail, so skipping")
        next
      end      
      logger.info("sending e-mail to #{recipient.id}:#{recipient.name}")
      
      # Make sure we have an authentication token for them to log in with
      # http://yekmer.posterous.com/single-access-token-using-devise
      recipient.ensure_authentication_token!
      
      cdata = {}
      cdata['item'] = self
      cdata['recipient'] = recipient      
      cdata['group'] = group if group
      #@cdata['attachments'] = @attachments
      
      if group and group.logo.exists? then
       cdata['logo'] = "#{BASEDOMAIN}#{group.logo.url}"
      else
        cdata['logo'] = nil
      end
      
      email = recipient.email
      
      if group and group.shortname.to_s != '' then
        msubject = "[#{group.shortname}] #{self.subject}"
      else
        msubject = subject
      end  
      
      if group
        #-- A group message  
        email = ItemMailer.group_item(msubject, self.html_content, recipient.email_address_with_name, cdata)
      else    
        email = ItemMailer.item(msubject, self.html_content, recipient.email_address_with_name, cdata)
      end

      begin
        logger.info("Item#emailit delivering email to #{recipient.id}:#{recipient.name}")
        email.deliver
        message_id = email.message_id
      rescue
        logger.info("Item#emailit problem delivering email to #{recipient.id}:#{recipient.name}")
      end
      
    end

  end
    
  def personal_twitter
    #-- Post to the participant's own twitter account
    
    # temporarily: problem with library
    return
    
    return if self.short_content.to_s == ''
    return if self.posted_by.to_i == 0
    @participant ||= Participant.find_by_id(self.posted_by)
    return if not ( @particpant and @participant.twitter_post and @participant.twitter_username.to_s !='' and @participant.twitter_oauth_token.to_s != '' )
    
    begin
      Twitter.configure do |config|
        config.consumer_key = TWITTER_CONSUMER_KEY
        config.consumer_secret = TWITTER_CONSUMER_SECRET
        config.oauth_token = @participant.twitter_oauth_token
        config.oauth_token_secret = @participant.twitter_oauth_secret
      end
      Twitter.update(self.short_content)
    rescue
      logger.info("Item#twitterit problem posting to twitter")
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
  
  def self.list_and_results(group_id=0,dialog_id=0,period_id=0,posted_by=0,posted_meta={},rated_meta={},rootonly=true,sortby='',participant_id=0)
    #-- Get a bunch of items, based on complicated criteria. Add up their ratings and value within just those items.
    #-- The criteria might include meta category of posters or of a particular group of raters. metamap_id => metamap_node_id
    #-- An array is being returned, optionally sorted
    
    dialog = Dialog.includes(:periods).find_by_id(dialog_id) if dialog_id.to_i > 0
    period = Period.find_by_id(period_id) if period_id.to_i > 0
    
    items = Item.scoped
    
    items = items.where("items.group_id = ?", group_id) if group_id.to_i > 0
    items = items.where("items.dialog_id = ?", dialog_id) if dialog_id.to_i > 0
    items = items.where("items.period_id = ?", period_id) if period_id.to_i > 0  
    items = items.where("is_first_in_thread=1") if rootonly
    items = items.where(:posted_by => posted_by) if posted_by.to_i > 0

    #-- We'll add up the stats, but we're including the overall rating summary anyway
    items = items.includes([:dialog,:group,:period,{:participant=>{:metamap_node_participants=>:metamap_node}},:item_rating_summary])
    #-- If a participant_id is given, we'll include that person's rating for each item, if there is any
    items = items.joins("left join ratings on (ratings.item_id=items.id and ratings.participant_id=#{participant_id})") if participant_id.to_i > 0
    items = items.select("items.*,ratings.participant_id as hasrating,ratings.approval as rateapproval,ratings.interest as rateinterest,'' as explanation") if participant_id.to_i > 0
    
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

    logger.info("item#list_and_results SQL: #{items.to_sql}")
    
    #-- Now we have the items. We'll sort them further down, after we have stats for them, in case we sort by that.

    #-- Get the actual ratings
    ratings = Rating.scoped
    ratings = ratings.where("ratings.dialog_id=#{dialog_id}") if dialog_id.to_i > 0
    ratings = ratings.where("items.period_id=#{period_id}") if period_id.to_i >0
    ratings = ratings.includes(:participant).includes(:item=>:item_rating_summary)
    if rated_meta
      rated_meta.each do |metamap_id,metamap_node_id| 
        if metamap_node_id.to_i > 0
          #-- Ratings must be by a participant in a particular meta category
          ratings = ratings.joins("inner join metamap_node_participants r_mnp_#{metamap_id} on (r_mnp_#{metamap_id}.participant_id=ratings.participant_id and r_mnp_#{metamap_id}.metamap_id=#{metamap_id} and r_mnp_#{metamap_id}.metamap_node_id=#{metamap_node_id})")
        end
      end
    end

    itemsproc = {}  # Stats for each item
    
    for item in items
      iproc = {'id'=>item.id,'name'=>item.participant.name,'subject'=>item.subject,'votes'=>0,'num_interest'=>0,'tot_interest'=>0,'avg_interest'=>0.0,'num_approval'=>0,'tot_approval'=>0,'avg_approval'=>0.0,'value'=>0.0,'int_0_count'=>0,'int_1_count'=>0,'int_2_count'=>0,'int_3_count'=>0,'int_4_count'=>0,'app_n3_count'=>0,'app_n2_count'=>0,'app_n1_count'=>0,'app_0_count'=>0,'app_p1_count'=>0,'app_p2_count'=>0,'app_p3_count'=>0,'controversy'=>0,'item'=>item}
      
      for rating in ratings
        if rating.item_id == item.id
          iproc['votes'] += 1
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
          iproc['value'] = iproc['avg_interest'] * iproc['avg_approval']
        end
      end
      iproc['controversy'] = (1.0 * ( iproc['app_n3_count'] * (-3.0 - iproc['avg_approval'])**2 + iproc['app_n2_count'] * (-2.0 - iproc['avg_approval'])**2 + iproc['app_n1_count'] * (-1.0 - iproc['avg_approval'])**2 + iproc['app_0_count'] * (0.0 - iproc['avg_approval'])**2 + iproc['app_p1_count'] * (1.0 - iproc['avg_approval'])**2 + iproc['app_p2_count'] * (2.0 - iproc['avg_approval'])**2 + iproc['app_p3_count'] * (3.0 - iproc['avg_approval'])**2 ) / iproc['num_approval']) if iproc['num_approval'] != 0
      itemsproc[item.id] = iproc
    end
    
    # We're probably no longer using the global numbers, as we've added them up just now
    # ['Value','items.value desc,items.id desc'],['Approval','items.approval desc,items.id desc'],['Interest','items.interest desc,items.id desc'],['Controversy','items.controversy desc,items.id desc']
  
    if sortby.to_s == 'default'
      @dialog = Dialog.find_by_id(@dialog_id)
      #items = Item.custom_item_sort(items, @page, @perscr, current_participant.id, @dialog).paginate :page=>@page, :per_page => @perscr
      items = Item.custom_item_sort(items, participant_id, @dialog)
    elsif sortby.to_s == '*value*' or sortby.to_s == ''
      itemsproc_sorted = itemsproc.sort {|a,b| [b[1]['value'],b[1]['votes'],b[1]['id']]<=>[a[1]['value'],a[1]['votes'],a[1]['id']]}
      outitems = []
      itemsproc_sorted.each do |item_id,iproc|
        outitems << iproc['item']
      end
      items = outitems
    elsif sortby == '*approval*'      
      itemsproc_sorted = itemsproc.sort {|a,b| [b[1]['avg_approval'],b[1]['votes'],b[1]['id']]<=>[a[1]['avg_approval'],a[1]['votes'],a[1]['id']]}
      outitems = []
      itemsproc_sorted.each do |item_id,iproc|
        outitems << iproc['item']
      end
      items = outitems
    elsif sortby == '*interest*'      
      itemsproc_sorted = itemsproc.sort {|a,b| [b[1]['avg_interest'],b[1]['votes'],b[1]['id']]<=>[a[1]['avg_interest'],a[1]['votes'],a[1]['id']]}
      outitems = []
      itemsproc_sorted.each do |item_id,iproc|
        outitems << iproc['item']
      end
      items = outitems
    elsif sortby == '*controversy*'      
      itemsproc_sorted = itemsproc.sort {|a,b| [b[1]['controversy'],b[1]['votes'],b[1]['id']]<=>[a[1]['controversy'],a[1]['votes'],a[1]['id']]}
      outitems = []
      itemsproc_sorted.each do |item_id,iproc|
        outitems << iproc['item']
      end
      items = outitems
    elsif sortby[0,5] == 'meta:'
      #-- NB: Not sure this is working !!
      metamap_id = sortby[5,10].to_i
      sortby = "metamap_nodes.name"
      items = items.where("metamap_nodes.metamap_id=#{metamap_id}")
    else
      items = items.order(sortby)
    end
    
    return [items, itemsproc]
    
  end

  def self.custom_item_sort(items, participant_id, dialog)
    #-- Create the default sort for items in a discussion:
    #-- current user's own item first
    #-- items he hasn't yet rated, alternating:
    #-- - from own gender
    #-- - from other genders
    #-- already rated items

    metamap_id = 3
    sort2 = 'date'

    if dialog and dialog.active_period
      metamap_id = dialog.active_period.sort_metamap_id if dialog.active_period.sort_metamap_id.to_i > 0
      sort2 = dialog.active_period.sort_order if dialog.active_period.sort_order.to_s != ''
    end
    
    if sort2 == 'value'
      sort2key = 'items.value desc'
    elsif sort2 = 'date'
      sort2key = 'items.id desc'
    else
      sort2key = 'items.id desc'
    end  
    
    #-- Sort by the secondary key first, so they're in that order already before putting them into different piles
    items = items.order(sort2key)
    
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
    
    newitems = own_items
    
    gotown = 0
    gotother = 0
    gotrated = 0
    
    isdone = false
    
    #-- Mix them together
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
   
  def voting_ok   
    #-- Decide whether the current user is allowed to rate the current item
    #-- The main reason should either be that voting manually is turned off, or voting period is over, and they already rated it
    if self.dialog
      if self.period_id.to_i > 0
        period = Period.find_by_id(self.period_id)
      end
      if not self.dialog.voting_open
      elsif self.period_id.to_i > 0 and not period
      elsif period and period.endrating.to_s != '' and Time.now.strftime("%Y-%m-%d") > period.endrating.strftime("%Y-%m-%d") and self['hasrating'].to_i > 0
        #-- The rating in the period is over, and this person rated the item
        logger.info("item#voting_ok #{self.id} already rated and period #{self.period_id} is over (#{Time.now.strftime("%Y-%m-%d")} > #{period.endrating})")
      else
        return true
      end
      return false
    else
      true
    end
  end  
  
  #def hasrating
  #  #-- Normally this is part of the query done, but in case it isn't let's look it up
  #  rating = Rating.where("item_id=#{self.id} and ratings.participant_id=#{current_participant.id}")
  #  rating.participant_id
  #end  
      
end
