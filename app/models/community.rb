class Community < ActiveRecord::Base

  has_many :community_admins
  has_many :participants, :through => :community_admins
  has_many :admins, -> { where "admin=1 and active=1"}, source: :participant, through: :community_admins
  has_many :moderators, -> { where "moderator=1 and active=1"}, source: :participant, through: :community_admins
  has_many :admins_and_moderators, -> { where "(moderator=1 or admin=1) and active=1"}, source: :participant, through: :community_admins

  has_many :conversation_communities
  has_many :conversations, :through => :conversation_communities

  has_attached_file :logo, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :path => "#{DATADIR}/:class/:attachment/:id/:style_:basename.:extension", :url => "/images/data/:class/:attachment/:id/:style_:basename.:extension"
  validates_attachment_content_type :logo, :content_type => /\Aimage\/.*\Z/

  attr_accessor :members
  attr_accessor :activity
  
  def name
    if self.fullname.to_s != ''
      self.fullname
    else
      self.tagname.capitalize
    end
  end
  
  def member_count
    Participant.tagged_with(self.tagname).where(status: 'active', no_email: false).count
  end
  
  def activity_count
    #-- Count the number of messages for that tag in the past month, based on hashtag and author  
    #Item.where("intra_com='@#{self.tagname}'").where('created_at > ?', 31.days.ago).count
    plist = Participant.tagged_with(self.tagname).collect {|p| p.id}.join(',')
    if plist != ''
      items = Item.includes(:participant).references(:participant).where("participants.id in (#{plist})")
      items = items.tagged_with(self.tagname).where('items.created_at > ?', 31.days.ago).count
    else
      return 0
    end
  end
  
  def activity_count_for_conversation(conversation, period)
    # period would be something like 2016-03-08_2017-06-23
    xarr = period.split('_')
    dstart = xarr[0]
    dend = xarr[1]
    
    plist = Participant.tagged_with(self.tagname).collect {|p| p.id}.join(',')
    if plist != ''
      items = Item.includes(:participant).references(:participant).where("participants.id in (#{plist})").where(conversation_id: conversation.id)
      items = items.tagged_with(self.tagname).where('items.created_at >= ?', dstart).where('items.created_at <= ?', dend).count
    else
      return 0
    end
  end
  
  def geo_counts
    members = Participant.tagged_with(self.tagname)
    nations = {}
    states = {}
    metros = {}
    cities = {}
    for member in members
      metros[member.metro_area_id] = true if member.metro_area_id.to_i > 0
      nations[member.country_code] = true if member.country_code.to_s != ''
      states[member.admin1uniq] = true if member.admin1uniq.to_s != ''
      cities[member.city.downcase] = true if member.city.to_s != ''      
    end
    return {nations: nations.length, states: states.length, metros: metros.length, cities: cities.length}
  end
  
  def go_to_conversation(participant)
    # Decide if we should go to a conversation, rather than the forum for this community
    conversation = nil
    if participant.tag_list.include?(self.tagname)
      # If we're in a community, and the user is a member. Conversation not specified. Figure out which one
      if self.conversations.length == 1
        # Community is in only one conversation, go there
        conversation = self.conversations[0]
      elsif self.conversations.length > 1
        # Community is in more than one conversation. Pick the last one.
        conversation = self.conversations.last
      end
    end
    if conversation
      return conversation.shortname
    end
    return ''
  end
  
  def is_admin(participant)
    if participant.sysadmin
      return true
    else
      admin = CommunityAdmin.where(["community_id = ? and participant_id = ?", self.id, participant.id]).first
      if admin
        return true
      end
    end  
  end
  
  def to_liquid
      {'id'=>id,'tagname'=>tagname,'description'=>description,'fullname'=>fullname, 'name'=>name}
  end
  
  
end
