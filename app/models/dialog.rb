class Dialog < ActiveRecord::Base
  has_many :dialog_admins
  has_many :dialog_groups
  has_many :groups, :through => :dialog_groups
  has_many :dialog_metamaps
  has_many :metamaps, :through => :dialog_metamaps
  has_many :items
  has_many :participants, :through => :dialog_admins
  belongs_to :creator, :class_name => "Participant", :foreign_key => :created_by
  belongs_to :maingroup, :class_name => "Group", :foreign_key => :group_id
  has_many :periods

  serialize :coordinators

  has_attached_file :logo, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :path => "#{DATADIR}/:class/:attachment/:id/:style_:basename.:extension", :url => "/images/data/:class/:attachment/:id/:style_:basename.:extension"  
  def metamaps
    #-- Get the metamaps associated with this dialog
    #-- [[2, "Nationality"], [3, "Gender"]]
    metamaps = []
    Metamap.joins(:dialogs).where("dialogs.id=?",id).order("sortorder,metamaps.name").each do |m|
      val = [m.id,m.name]
      metamaps << val if not metamaps.include?(val)
    end
    metamaps.uniq
  end  
  
  def to_liquid
      {'id'=>id,'name'=>name,'shortname'=>shortname,'description'=>description}
  end
  
end
