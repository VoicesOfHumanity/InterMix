class Group < ActiveRecord::Base
  has_many :group_participants
  has_many :participants, :through => :group_participants
  has_many :moderators, :source => :participant, :through => :group_participants, :conditions => "moderator=1 and active=1"
  #has_many :active_members, :source => :participant, :through => :group_participants, :conditions => "participants.status='active' and group_participants.active=1"
  #has_many :non_active_members, :source => :participant, :through => :group_participants, :conditions => "participants.status!='active' or group_participants.active!=1"
  has_many :dialog_groups
  has_many :dialogs, :through => :dialog_groups
  #has_many :active_dialogs, :source => :dialog, :through => :dialog_groups, :conditions => "active=1"
  #has_many :pending_dialogs, :source => :dialog, :through => :dialog_groups, :conditions => "!(active=1)"
  has_many :group_metamaps
  has_many :metamaps, :through => :group_metamaps
  #has_and_belongs_to_many :participants, :join_table => :group_participants
  has_many :items
  has_many :ratings
  has_many :templates
  has_many :messages, :primary_key => :to_group_id
  belongs_to :owner_participant, :class_name => "Participant", :foreign_key => :owner
  has_many :periods
  has_many :group_subtags
  
  has_attached_file :logo, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :path => "#{DATADIR}/:class/:attachment/:id/:style_:basename.:extension", :url => "/images/data/:class/:attachment/:id/:style_:basename.:extension"
  
  #validates_presence_of     :name, :shortname, :visibility, :openness, :owner

  def active_members
    members = Participant.includes(:group_participants).where("group_participants.group_id=#{self.id} and group_participants.participant_id=participants.id").where("participants.status='active' and group_participants.active=1").all
  end
  
  def non_active_members
    members = Participant.includes(:group_participants).where("group_participants.group_id=#{self.id} and group_participants.participant_id=participants.id").where("participants.status!='active' or participants.status is null or group_participants.active!=1").all
  end
  
  def members_with_group_participants
    #-- To make sure that we don't get some group_participants records that don't belong
    members = Participant.includes(:group_participants).where("group_participants.group_id=#{self.id} and group_participants.participant_id=participants.id").all    
  end  

  def dialogs_in
    #-- What dialogs does this group participate in?
    #-- [[2, "Individual Initiatives for Nuclear Disarmament"], [3, "What's the best apple pie recipe?"]]
    dialogsin = []
    gdialogsin = DialogGroup.where("group_id=#{id}").includes(:dialog).all
    gdialogsin.each do |g|
      val = [g.dialog.id,g.dialog.name]
      dialogsin << val if not dialogsin.include?(val)
    end
    dialogsin.uniq 
  end
  
  def active_dialogs
    dialogs = Dialog.includes(:dialog_groups).where("dialog_groups.group_id=#{self.id}").where("dialog_groups.active=1").all
  end
  
  def pending_dialogs
    dialogs = Dialog.includes(:dialog_groups).where("dialog_groups.group_id=#{self.id}").where("!(dialog_groups.active=1)").all
  end    

  def metamaps_own
    metamaps
  end  
    
  def metamaps_all
    #-- Figure out what metamaps apply to this group, based on dialogs it is in
    #-- [[2, "Nationality"], [3, "Gender"]]
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
  
  def adminname
    begin
      owner_participant.name
    rescue
      '???'
    end  
  end  

  def to_liquid
      {'id'=>id,'name'=>name,'shortname'=>shortname,'description'=>description}
  end
  
  def self.findornot(id)
    id = id.to_i
    return nil if id<=0
    begin
      client = find(id)
    rescue
    end  
    if client
      return client
    else
      return nil
    end        
  end  
  
  def mysubtags(participant)
    #-- Return only those group_subtags that the person follows, or all if they're an admin
    subtags = []
    for subtag in self.group_subtags
      if participant.group_subtags.includes?(subtag)
        subtags << subtag
      end  
    end
    subtags
  end  
  
end
