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
    #-- NOT filtered on no_email, deliberately. Membership has nothing to do with email
    #-- preference, and every text a user reads before opting out says so: front#optout
    #-- promises only to "stop receiving emails", and the profile setting is labelled
    #-- "Block all emails?". Neither mentions being hidden from other members.
    #--
    #-- The no_email filter was also not protecting against deleted accounts: the
    #-- delete-account path sets status='removed' as well, so `status: 'active'` already
    #-- excludes them. What it actually did was hide 643 of 1259 active participants
    #-- (2026-07-30) from member lists and counts purely for opting out of email, so
    #-- every community's member count was understating by roughly half.
    #--
    #-- The mail paths that SHOULD honour no_email do it themselves and are untouched:
    #-- mail_send.rb's audience query, groups_controller#807, Item#481, Message#33.
    Participant.tagged_with(self.tagname).where(status: 'active').count
  end
  
  #-- Batched form of activity_count: one grouped query for any number of communities.
  #-- The index page used to call activity_count once per community — 454 queries for 359
  #-- communities at ~3.3ms each, which was the real cost of that page (not the per-call
  #-- object churn the audit flagged). Returns a Hash of downcased tagname => count,
  #-- defaulting to 0 for tagnames with no activity.
  #--
  #-- The SQL deliberately mirrors what acts-as-taggable-on generates, and two details of
  #-- that are easy to get wrong:
  #--   * Matching is case-INsensitive. With strict_case_match=false the gem emits
  #--     LOWER(tags.name) LIKE …, so we compare on LOWER() and group by it. Author and item
  #--     tags are matched by lowercased NAME rather than tag_id, so two tag rows differing
  #--     only in case still pair up the way tagged_with would.
  #--   * There is NO context filter. tagged_with does not restrict taggings.context, and
  #--     Item is also acts_as_taggable_on :subgroups — there are more Item/subgroups
  #--     taggings than Item/tags ones, so adding "context = 'tags'" here would silently
  #--     change the numbers.
  def self.activity_counts(tagnames, since: 31.days.ago)
    names = Array(tagnames).map { |t| t.to_s.downcase }.reject(&:empty?).uniq
    return Hash.new(0) if names.empty?

    sql = sanitize_sql_array([<<~SQL, names, since])
      SELECT LOWER(item_tags.name) AS tag, COUNT(DISTINCT items.id) AS n
        FROM items
        INNER JOIN taggings item_tg
                ON item_tg.taggable_id = items.id
               AND item_tg.taggable_type = 'Item'
        INNER JOIN tags item_tags
                ON item_tags.id = item_tg.tag_id
        INNER JOIN taggings author_tg
                ON author_tg.taggable_id = items.posted_by
               AND author_tg.taggable_type = 'Participant'
        INNER JOIN tags author_tags
                ON author_tags.id = author_tg.tag_id
               AND LOWER(author_tags.name) = LOWER(item_tags.name)
       WHERE LOWER(item_tags.name) IN (?)
         AND items.created_at > ?
       GROUP BY LOWER(item_tags.name)
    SQL

    connection.select_all(sql).each_with_object(Hash.new(0)) do |row, counts|
      counts[row['tag']] = row['n'].to_i
    end
  end

  def activity_count
    #-- Count the number of messages for that tag in the past month, based on hashtag and
    #-- author. Delegates to the batched query so there is only one implementation to keep
    #-- correct; prefer Community.activity_counts when handling more than one community.
    self.class.activity_counts([tagname])[tagname.to_s.downcase]
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
    #-- no_email filter removed 2026-07-30 -- see member_count above for why.
    members = Participant.tagged_with(self.tagname).where(status: 'active')
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
