class Participant < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable, :timeoutable, :token_authenticatable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  devise :omniauthable, :omniauth_providers => [:facebook]

  # Setup accessible (or protected) attributes for your model
  #attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :title, :address1, :address2, :city, :admin1uniq, :county_code, :county_name, :state_code, :state_name, :country_code, :country_name, :phone, :zip, :metropolitan_area, :metro_area_id, :bioregion, :bioregion_id, :faith_tradition, :faith_tradition_id, :political, :political_id, :status, :self_description, :tag_list, :visibility, :twitter_post, :twitter_username, :forum_email, :group_email, :subgroup_email, :private_email, :system_email, :no_email, :authentication_token, :picture
  acts_as_taggable

  has_many :group_participants, :dependent => :destroy
  #has_and_belongs_to_many :groups, :join_table => :group_participants
  has_many :groups, :through => :group_participants
  has_many :dialogs, :through => :dialog_admins
  has_many :items, :foreign_key => :posted_by
  has_many :ratings
  has_many :authentications, :dependent => :destroy
  has_many :dialog_admins, :dependent => :destroy
  belongs_to :geocountry, :foreign_key => :country_code, :primary_key => :iso
  belongs_to :geoadmin1, :foreign_key => :admin1uniq, :primary_key => :admin1uniq
  belongs_to :metro_area
  has_many :group_subtag_participants
  has_many :group_subtags, :through => :group_subtag_participants
  
  has_many :followeds, :class_name => 'Follow', :foreign_key => :followed_id, :dependent => :destroy
  has_many :followings, :class_name => 'Follow', :foreign_key => :following_id, :dependent => :destroy
  
  has_many :followers, :class_name => 'Participant', :through => :followeds
  has_many :idols, :class_name => 'Participant', :through => :followings
  
  has_many :sent_messages, :class_name => 'Message', :primary_key => :from_participant_id
  has_many :received_messages, :class_name => 'Message', :primary_key => :to_participant_id
  
  has_many :metamap_node_participants, :dependent => :destroy
  has_many :metamaps, :through=>:metamap_node_participants
  has_many :metamap_nodes, :through=>:metamap_node_participants

  #has_many :gender_metamap_node_participants, :class_name => "MetamapNodeParticipant", :conditions => "metamap_id=3"
  #has_many :gender_metamap_nodes, :source => :metamap_node_participants
  #has_many :gender_metamap_nodes, :class_name => "MetamapNode", :through=>:metamap_node_participants  
  #has_many :gender_metamap_node, :through=>:metamap_node_participants, :source=>'metamap_node', :conditions => "metamap_id=3"
  
  serialize :forum_settings, :check_boxes

  has_attached_file :picture, :styles => { :medium => "300x300>", :thumb => "50x50#" }, :path => "#{DATADIR}/:class/:attachment/:id/:style_:basename.:extension", :url => "/images/data/:class/:attachment/:id/:style_:basename.:extension"
  validates_attachment_content_type :picture, :content_type => /\Aimage\/.*\Z/
  
  def name
    name = "#{first_name.to_s} #{last_name.to_s}".strip
    name = "???" if name == ''
    return name
  end  
  
  def email_address_with_name
    return "\"#{first_name.to_s} #{last_name.to_s}\" <#{email}>"
  end
  
  def self.tags
    tag_counts.collect {|t| t.name}.join(', ')  
  end
  
  def to_liquid
      {'id'=>id,'name'=>name,'first_name'=>first_name,'last_name'=>last_name,'email'=>email,'title'=>title,'self_description'=>self_description,'city'=>city,'country_name'=>country_name,'authentication_token'=>authentication_token,'fb_uid'=>fb_uid}
  end
  
  def apply_omniauth(omniauth)
    xemail = (omniauth['info']) ? omniauth['info']['email'] : '???'
    xprov = omniauth['provider'] ? omniauth['provider'] : '???'
    xuid = omniauth['uid'] ? omniauth['uid'] : '???'
    logger.info("apply_omniauth email:#{xemail} provider:#{xprov} uid:#{xuid}")
    get_fields_from_omniauth(omniauth)
    authentications.build(:provider => omniauth['provider'], :uid => omniauth['uid'])
  end
  
  def get_fields_from_omniauth(omniauth)
    logger.info("participant#get_fields_from_omniauth #{omniauth['provider']}")
    case omniauth['provider']
    when 'facebook'
      if ['info']
        self.email = omniauth['info']['email'] if email.blank?
        if omniauth['info'].has_key?('first_name')
          self.first_name = omniauth['info']['first_name'] if first_name.blank?
          self.last_name = omniauth['info']['last_name'] if last_name.blank?
        elsif omniauth['info'].has_key?('name')
          narr = omniauth['info']['name'].split(' ')
          self.last_name = narr[narr.length-1]
          self.first_name = ''
          self.first_name = narr[0,narr.length-1].join(' ') if narr.length > 1          
        end
        self.fb_link = omniauth['info']['urls']['Facebook'] if omniauth['info']['urls'] and omniauth['info']['urls']['Facebook']
        self.fb_uid = omniauth['uid']
      else
        logger.info("participant#get_fields_from_omniauth Didn't get any omniauth['info']")  
      end
    when 'twitter'
      if omniauth['user_info']
        #self.email = omniauth['user_info']['email'] if email.blank?
        name_arr = omniauth['info']['name'].split(' ')
        self.first_name = name_arr[0] if first_name.blank?
        self.last_name = name_arr[1] if last_name.blank? and name_arr.length > 1
      end
    else
      if omniauth['info']
        self.email = omniauth['info']['email'] if email.blank?   
      end     
    end    
    logger.info("participant#get_fields_from_omniauth e-mail is now #{self.email}")  
  end  

  def password_required?
    (authentications.empty? || !password.blank?) && super
  end
  
  def ensure_authentication_token!   
    # http://yekmer.posterous.com/single-access-token-using-devise
    # reset_authentication_token! if authentication_token.blank?   
    # replaced with this. https://gist.github.com/josevalim/fb706b1e933ef01e4fb6
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
      self.save
    end
  end
  
  def has_required
    #-- Has the required profile fields and meta tags been entered for this participant?
    ok = true
    exp = ''
    if first_name.to_s == '' or last_name == ''
      ok = false
      exp = "name"
    elsif country_code.to_s == ''
      ok = false
      exp = "country_code"
    elsif visibility.to_s == ''
      ok = false
      exp = "visibility"
    elsif private_email.to_s == '' or system_email.to_s == '' or forum_email.to_s == ''
      ok = false
      exp = "email settings"
    else  
      #-- everything in metamaps_h should be filled in
      mnodes = metamap_nodes_h
      metamaps_h.each do |metamap_id,metamap_name,metamap|
        mnode = mnodes[metamap_id] ? mnodes[metamap_id] : nil
        if mnode 
          if metamap.binary
          else
            if mnode[1].to_i == 0
              ok = false
              exp += "metamap#{metamap_id} "  
            end
          end  
        else
          ok = false
          exp += "metamap#{metamap_id} "  
        end
      end 
    end
    if ok and !required_entered
      self.required_entered = true
      logger.info("participant#has_required profile requirements are now OK")
      self.save
    elsif !ok and required_entered
      self.required_entered = false
      logger.info("participant#has_required profile requirements are now NOT ok")
      self.save
    end    
    logger.info("participant#has_required: #{ok ? "OK" : "NO"} #{exp}")
    return ok  
  end
  
  def groups_in
    #-- What groups are they in?
    #-- [[5, "Test group"], [7, "The Real Men"], [8, "Individual Initiatives for Nuclear Disarmament"]]
    gpin = GroupParticipant.where("participant_id=#{id}").includes(:group)
    groupsin = gpin.collect{|g| [g.group_id,(g.group ? g.group.name : "Unknown Group")] }
    groupsin.uniq
  end  
  
  def dialogs_in
    #-- What dialogs are they in, via the groups they're in
    #-- [[2, "Individual Initiatives for Nuclear Disarmament"], [3, "What's the best apple pie recipe?"]]
    groupsin = groups_in
    dialogsin = []
    for group in groupsin
      group_id = group[0]
      group_name = group[1]
      gdialogsin = DialogGroup.where("group_id=#{group_id}").includes(:dialog)
      gdialogsin.each do |g|
        if g.dialog
          val = [g.dialog.id,g.dialog.name]
          dialogsin << val if not dialogsin.include?(val)
        end
      end
    end  
    dialogsin.uniq
  end
  
  def metamaps_h
    #-- Figure out what metamaps/nodes apply to this person, based on groups or discussions they are in,
    #-- plus what is globally required
    #-- [[2, "Nationality"], [3, "Gender"]]
    #-- NB: This was colliding with the metamaps association, so it had to be renamed
    metamaps = []
    dialogsin = dialogs_in
    logger.info("participant#metamaps_h is in #{dialogs_in.length} discussions")
    for d in dialogsin
      Metamap.joins(:dialogs).where("dialogs.id=?",d[0]).order("sortorder,metamaps.name").each do |m|
        val = [m.id,m.name,m]
        metamaps << val if not metamaps.include?(val)
      end
    end   
    groupsin = groups_in
    logger.info("participant#metamaps_h is in #{groups_in.length} groups")
    for g in groupsin
      Metamap.joins(:groups).where("groups.id=?",g[0]).order("sortorder,metamaps.name").each do |m|
        val = [m.id,m.name,m]
        metamaps << val if not metamaps.include?(val)
      end
    end
    rmetamaps = Metamap.where(global_default: true)
    logger.info("participant#metamaps_h There are #{rmetamaps.length} global defaults")
    for m in rmetamaps
      val = [m.id,m.name,m]
      metamaps << val if not metamaps.include?(val)
    end      
    metamaps.uniq
  end
  
  def metamap_nodes_h
    #-- Get the current value/name for each, for this user
    #-- {2=>["Nationality", 59, "Danish",""], 3=>["Gender affinity", 207, "male", "Men"], 9=>["Indigenous"", true, ""]}
    #-- NB: This was colliding with the metamap_nodes association
    metamap_nodes = {}
    for m in metamaps
      #metamap_id = m[0]
      #metamap_name = m[1]
      metamap_id = m.id
      metamap_name = m.name
      mnps = MetamapNodeParticipant.where(:metamap_id=>metamap_id, :participant_id=>id).includes(:metamap_node)
      if mnps.length > 0
        # A value has been selected for this metamap for this user
        mnp = mnps[0]
        metamap_node_id = mnp.metamap_node_id
        name = mnp.metamap_node.name
        name_as_group = mnp.metamap_node.name_as_group
        if m.binary
          # For binary metamaps, where there's only a yes and a no value possible, return the binary value, rather than the node id
          metamap_nodes[metamap_id] = [metamap_name, mnp.metamap_node.binary_on, name, name_as_group]
        else
          metamap_nodes[metamap_id] = [metamap_name, metamap_node_id, name, name_as_group]
        end
      else
        # Nothing filled in for this metamap for this user
        if m.binary
          metamap_nodes[metamap_id] = [metamap_name, false, '', '']
        else
          metamap_nodes[metamap_id] = [metamap_name, 0, '', '']
        end
      end
    end
    metamap_nodes
  end
  
  def gender
    self.metamap_nodes.each do |mn|
      if mn.metamap_id == 3
        return mn.name
      end
    end  
    return '???'
  end
  
  def generation
    self.metamap_nodes.each do |mn|
      if mn.metamap_id == 5
        return mn.name
      end
    end  
    return '???'
  end
  
  def them
    #-- Return him, her, them, depending on what we know about their gender
    if self.gender == 'male'
      'him'
    elsif self.gender == 'female'
      'her'
    else
      'them'    
    end
  end  
  
  def contacts
    ( self.followers + self.idols ).uniq
  end    
  
  def show_tag_list(with_links=false)
    xlist = ''
    tags.each do |tag|
      xlist += ', ' if xlist != ''
      xlist += '@'
      if with_links
        xlist += "<a href=\"/dialogs/#{VOH_DISCUSSION_ID}/slider?comtag=#{tag.name}\">" + tag.name + "</a>"
      else
        xlist += tag.name
      end 
    end
    xlist
  end
      
  private
  
  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless Participant.where(authentication_token: token).first
    end
  end
      
end
