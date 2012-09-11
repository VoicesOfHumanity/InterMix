class Participant < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable, :timeoutable 
  devise :database_authenticatable, :token_authenticatable, :omniauthable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :title, :address1, :address2, :city, :admin1uniq, :county_code, :county_name, :state_code, :state_name, :country_code, :country_name, :phone, :zip, :metropolitan_area, :metro_area_id, :bioregion, :bioregion_id, :faith_tradition, :faith_tradition_id, :political, :political_id, :status, :self_description, :tag_list, :visibility, :twitter_post, :twitter_username, :forum_email, :group_email, :private_email, :system_email, :no_email, :authentication_token
  acts_as_taggable

  has_many :group_participants
  #has_and_belongs_to_many :groups, :join_table => :group_participants
  has_many :groups, :through => :group_participants
  has_many :dialogs, :through => :dialog_admins
  has_many :items, :foreign_key => :posted_by
  has_many :ratings
  has_many :authentications
  has_many :dialog_admins
  belongs_to :metro_area
  has_many :group_subtags, :through => :group_subtag_participants
  
  has_many :followeds, :class_name => 'Follow', :foreign_key => :followed_id
  has_many :followings, :class_name => 'Follow', :foreign_key => :following_id
  
  has_many :followers, :class_name => 'Participant', :through => :followeds
  has_many :idols, :class_name => 'Participant', :through => :followings
  
  has_many :sent_messages, :class_name => 'Message', :primary_key => :from_participant_id
  has_many :received_messages, :class_name => 'Message', :primary_key => :to_participant_id
  
  has_many :metamap_node_participants
  has_many :metamaps, :through=>:metamap_node_participants
  has_many :metamap_nodes, :through=>:metamap_node_participants
  
  serialize :forum_settings
  
  def name
    name = "#{first_name.to_s} #{last_name.to_s}".strip
    name = "???" if name == ''
    return name
  end  
  
  def email_address_with_name
    return "#{first_name.to_s} #{last_name.to_s} <#{email}>"
  end
  
  def self.tags
    tag_counts.collect {|t| t.name}.join(', ')  
  end
  
  def to_liquid
      {'id'=>id,'name'=>name,'first_name'=>first_name,'last_name'=>last_name,'email'=>email,'title'=>title,'self_description'=>self_description,'city'=>city,'country_name'=>country_name}
  end
  
  def apply_omniauth(omniauth)
    xemail = (omniauth['extra'] and omniauth['extra']['user_hash']) ? omniauth['extra']['user_hash']['email'] : '???'
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
      if omniauth['extra']
        self.email = omniauth['extra']['user_hash']['email'] if email.blank?
        self.first_name = omniauth['extra']['user_hash']['first_name'] if first_name.blank?
        self.last_name = omniauth['extra']['user_hash']['last_name'] if last_name.blank?
        self.fb_uid = omniauth['uid']
        self.fb_link = omniauth['user_info']['urls']['Facebook']
      else
        logger.info("participant#get_fields_from_omniauth Didn't get any omniauth['extra']")  
      end
    when 'twitter'
      if omniauth['user_info']
        #self.email = omniauth['user_info']['email'] if email.blank?
        name_arr = omniauth['user_info']['name'].split(' ')
        self.first_name = name_arr[0] if first_name.blank?
        self.last_name = name_arr[1] if last_name.blank? and name_arr.length > 1
      end
    else
      if omniauth['user_info']
        self.email = omniauth['user_info']['email'] if email.blank?   
      end     
    end    
    logger.info("participant#get_fields_from_omniauth e-mail is now #{self.email}")  
  end  

  def password_required?
    (authentications.empty? || !password.blank?) && super
  end
  
  def ensure_authentication_token!   
    # http://yekmer.posterous.com/single-access-token-using-devise
    reset_authentication_token! if authentication_token.blank?   
  end
  
  def groups_in
    #-- What groups are they in?
    #-- [[5, "Test group"], [7, "The Real Men"], [8, "Individual Initiatives for Nuclear Disarmament"]]
    gpin = GroupParticipant.where("participant_id=#{id}").includes(:group).all
    groupsin = gpin.collect{|g| [g.group.id,g.group.name] }
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
      gdialogsin = DialogGroup.where("group_id=#{group_id}").includes(:dialog).all
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
    #-- Figure out what metamaps/nodes apply to this person, based on groups or discussions they are in
    #-- [[2, "Nationality"], [3, "Gender"]]
    #-- NB: This was colliding with the metamaps association
    dialogsin = dialogs_in
    metamaps = []
    for d in dialogsin
      Metamap.joins(:dialogs).where("dialogs.id=?",d[0]).order("sortorder,metamaps.name").each do |m|
        val = [m.id,m.name]
        metamaps << val if not metamaps.include?(val)
      end
    end
    metamaps.uniq
  end
  
  def metamap_nodes_h
    #-- Get the current value/name for each, for this user
    #-- {2=>["Nationality", 59, "Danish"], 3=>["Gender", 207, "Male"]}
    #-- NB: This was colliding with the metamap_nodes association
    metamap_nodes = {}
    for m in metamaps
      #metamap_id = m[0]
      #metamap_name = m[1]
      metamap_id = m.id
      metamap_name = m.name
      mnps = MetamapNodeParticipant.where(:metamap_id=>metamap_id, :participant_id=>id).includes(:metamap_node)
      if mnps.length > 0
        mnp = mnps[0]
        metamap_node_id = mnp.metamap_node_id
        name = mnp.metamap_node.name
        metamap_nodes[metamap_id] = [metamap_name,metamap_node_id,name]
      else
        metamap_nodes[metamap_id] = [metamap_name,0,'']
      end
    end
    metamap_nodes
  end
      
end
