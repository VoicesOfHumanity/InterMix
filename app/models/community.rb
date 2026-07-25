class Community < ActiveRecord::Base

  has_many :community_admins
  has_many :community_participants
  has_many :participants, :through => :community_participants
  #has_many :participants, :through => :community_admins
  has_many :admins, -> { where "admin=1 and active=1"}, source: :participant, through: :community_admins
  has_many :moderators, -> { where "moderator=1 and active=1"}, source: :participant, through: :community_admins
  has_many :admins_and_moderators, -> { where "(moderator=1 or admin=1) and active=1"}, source: :participant, through: :community_admins
  belongs_to :conversation, optional: true

  belongs_to :creator, optional: true, class_name: 'Participant', foreign_key: :created_by
  belongs_to :administrator, optional: true, class_name: 'Participant', foreign_key: :administrator_id

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
    #-- Called once per community on the communities index, so this runs hundreds of times
    #-- per page. It used to load every tagged participant as a full AR object just to read
    #-- their ids, interpolate those ids into a literal "participants.id in (…)" string, and
    #-- then LEFT JOIN + eager-load participants purely to COUNT rows. Now: pluck the ids
    #-- (no objects instantiated, no unbounded SQL string) and filter on items.posted_by,
    #-- which is what belongs_to :participant maps to anyway — so the join disappears.
    #-- Deliberately still an IN list rather than a subquery: the production box is old
    #-- MySQL, where IN (SELECT …) can be re-evaluated per row and would risk being slower
    #-- than what it replaces. Worth trying the subquery form on staging where it can be
    #-- measured.
    author_ids = Participant.tagged_with(self.tagname).pluck('participants.id').uniq
    return 0 if author_ids.empty?
    Item.tagged_with(self.tagname)
        .where(posted_by: author_ids)
        .where('items.created_at > ?', 31.days.ago)
        .count
  end
  
  def activity_count_for_conversation(conversation, period)
    # period would be something like 2016-03-08_2017-06-23
    xarr = period.split('_')
    dstart = xarr[0]
    dend = xarr[1]
    logger.info("community#activity_count_for_conversation #{conversation.id}: period:#{period}: #{dstart} - #{dend}")
    plist = Participant.tagged_with(self.tagname).collect {|p| p.id}.join(',')
    if plist != ''
      items = Item.includes(:participant).references(:participant).where("participants.id in (#{plist})").where(conversation_id: conversation.id)
      items = items.tagged_with(self.tagname).where('items.created_at >= ?', dstart).where('items.created_at <= ?', dend).count
    else
      return 0
    end
  end
  
  def geo_counts
    members = #Participant.tagged_with(self.tagname)
    members = Participant.tagged_with(self.tagname).where(status: 'active', no_email: false)
    logger.info("community#geo_counts #{members.length} members")
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
    if participant.tag_list_downcase.include?(self.tagname.downcase)
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
  
  def is_member(participant)
    if participant.sysadmin
      return true
    else
      return participant.tag_list_downcase.include? self.tagname.downcase
    end  
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
