class Group < ActiveRecord::Base
  has_many :group_participants
  has_many :participants, :through => :group_participants
  has_many :dialog_groups
  has_many :dialogs, :through => :dialog_groups
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

  def metamaps
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
  
end
