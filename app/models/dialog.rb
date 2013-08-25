class Dialog < ActiveRecord::Base
  has_many :dialog_admins
  has_many :dialog_groups
  has_many :groups, :through => :dialog_groups
  #has_many :active_groups, :source => :group, :through => :dialog_groups, :conditions => "dialog_groups.active=1"
  #has_many :pending_groups, :source => :group, :through => :dialog_groups, :conditions => "!(dialog_groups.active=1)"
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
  
  def active_groups
    groups = Group.includes(:dialog_groups).where("dialog_groups.dialog_id=#{self.id.to_i} and dialog_groups.active=1").all
  end
  
  def pending_groups
    groups = Group.includes(:dialog_groups).where("dialog_groups.dialog_id=#{self.id.to_i}").where("!(dialog_groups.active=1)").all
  end  
  
  def settings_with_period
    #-- Get some settings, either from the dialog record, or, if a period is active, from the period
    settings = {
      "max_characters" => self.max_characters.to_i,
      "max_words" => self.max_words.to_i,
      "metamap_vote_own" => self.metamap_vote_own,
      "default_message" => self.default_message,
      "required_message" => self.required_message,
      "required_subject" => self.required_subject,
      "max_messages" => self.max_messages.to_i,
      "new_message_title" => self.new_message_title,
      "allow_replies" => self.allow_replies,
      "required_meta" => self.required_meta,
      "value_calc" => self.value_calc,
      "profiles_visible" => self.profiles_visible,
      "names_visible_voting" => self.names_visible_voting,
      "names_visible_general" => self.names_visible_general,
      "in_voting_round" => self.in_voting_round,
      "posting_open" => self.posting_open,
      "voting_open" => self.voting_open
    }
    if self.current_period.to_i > 0
      xperiod = Period.find_by_id(self.current_period)
      settings["max_characters"] = xperiod.max_characters
      settings["max_words"] = xperiod.max_words
      settings["metamap_vote_own"] = xperiod.metamap_vote_own
      settings["default_message"] = xperiod.default_message
      settings["required_message"] = xperiod.required_message
      #settings["required_subject"] = period.required_subject
      settings["max_messages"] = xperiod.max_messages
      settings["new_message_title"] = xperiod.new_message_title
      settings["allow_replies"] = xperiod.allow_replies
      settings["required_meta"] = xperiod.required_meta
      settings["value_calc"] = xperiod.value_calc
      settings["profiles_visible"] = xperiod.profiles_visible
      settings["names_visible_voting"] = xperiod.names_visible_voting
      settings["names_visible_general"] = xperiod.names_visible_general
      #settings["in_voting_round"] = period.in_voting_round
      #settings["posting_open"] = period.posting_open
      #settings["voting_open"] = period.voting_open
    end
    settings
  end
  
  def active_period
    if self.current_period.to_i >0
      active_period = Period.find_by_id(self.current_period)
    else
      nil
    end
  end
  
  def recent_period
    #-- Find the most recent period
    p = self.active_period
    if p
      p
    else
      p = Period.where("dialog_id=#{self.id}").order("id").last
    end    
  end  
  
  def to_liquid
      {'id'=>id,'name'=>name,'shortname'=>shortname,'description'=>description}
  end
  
end
