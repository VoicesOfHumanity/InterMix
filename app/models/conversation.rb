class Conversation < ApplicationRecord
  has_many :conversation_communities
  has_many :communities, :through => :conversation_communities
  
  attr_accessor :activity
  attr_accessor :perspective
  
  def activity_count
    #-- Count the number of messages in the conversation in the past month 
    #Item.where("intra_com='@#{self.tagname}'").where('created_at > ?', 31.days.ago).count    
    Item.where("conversation_id=#{self.id}").where('created_at > ?', 31.days.ago).count
  end
  
  def is_member_of(p)
    # Figure out if somebody is a member of one of the member communities, and thus member of the conversation
    for com_tag in p.tag_list
      community = Community.find_by_tagname(com_tag)
      if community.conversations.include?(self)
        return true
      end
    end
    return false
  end
  
end
