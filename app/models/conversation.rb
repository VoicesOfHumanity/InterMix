class Conversation < ApplicationRecord
  has_many :conversation_communities
  has_many :communities, :through => :conversation_communities
  has_many :items
  
  serialize :topics
  
  attr_accessor :activity
  attr_accessor :perspective
  attr_accessor :perspectives
  
  def activity_count(period='')
    #-- Count the number of messages in the conversation in the past month 
    #Item.where("conversation_id=#{self.id}").where('created_at > ?', 31.days.ago).count
    # period would be something like 2016-03-08_2017-06-23
    if period
      xarr = period.split('_')
      dstart = xarr[0]
      dend = xarr[1]
      xcount = Item.where("conversation_id=#{self.id}").where('items.created_at >= ?', dstart).where('items.created_at <= ?', dend).count
    else
      xcount = Item.where("conversation_id=#{self.id}").where('created_at > ?', 31.days.ago).count      
    end
    xcount
  end
  
  def is_member_of(p)
    # Figure out if somebody is a member of one of the member communities, and thus member of the conversation
    for com_tag in p.tag_list_downcase
      community = Community.find_by_tagname(com_tag)
      if community and community.conversations and community.conversations.include?(self)
        return true
      end
    end
    return false
  end

  def is_admin(participant)
    if participant.sysadmin
      return true
    end  
  end
  
  def topic_list
    if self.topics and self.topics.class.name == 'Array'
      if self.topics.length > 0
        return self.topics.uniq.join(', ')
      end
    end
    return ''
  end
  
  def to_liquid
      {'id'=>id, 'shortname'=>shortname,'name'=>name, 'description'=>description}
  end
  
end
