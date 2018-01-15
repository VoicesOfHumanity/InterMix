class Community < ActiveRecord::Base

  has_many :community_admins
  has_many :participants, :through => :community_admins
  has_many :admins, -> { where "admin=1 and active=1"}, source: :participant, through: :community_admins
  has_many :moderators, -> { where "moderator=1 and active=1"}, source: :participant, through: :community_admins

  has_attached_file :logo, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :path => "#{DATADIR}/:class/:attachment/:id/:style_:basename.:extension", :url => "/images/data/:class/:attachment/:id/:style_:basename.:extension"
  validates_attachment_content_type :logo, :content_type => /\Aimage\/.*\Z/

  attr_accessor :members
  attr_accessor :activity
  
  def member_count
    Participant.tagged_with(self.tagname).count
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
  
end
