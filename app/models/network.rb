class Network < ApplicationRecord

  has_many :network_communities
  has_many :communities, :through => :network_communities
  belongs_to :participant, :foreign_key => :created_by

  attr_accessor :activity
  
  serialize :communityarray

  def community_tags
    self.communities.collect{|com| com.tagname}
  end

  def activity_count
    #-- Count the number of messages in the network in the past month 
    #-- To count as being posted in the network, a message must have hashtags for all of the network communities and the other must have the proper settings.

    # The tags are in item.tag_list, but not sure how to do a query based on and-and there
    
    #NOT DONE

    #q = Item.where('created_at > ?', 31.days.ago)
    
    #q = q.tagged_with(self.community_tags)
    
    #for tag in self.community_tags
    #  q = q.where("html_content like '##{tag}'")
    #end
    #q.count    
    0
  end
  
  def members
    # A member is something who's in all the communities and has all the other settings too
    members = Participant.tagged_with(self.community_tags).where(status: 'active', no_email: false)    
    if self.age > 0
      members = members.joins("inner join metamap_node_participants p_mnp_5 on (p_mnp_5.participant_id=participants.id and p_mnp_5.metamap_id=5 and p_mnp_5.metamap_node_id=#{self.age})")   
    end
    if self.gender > 0
      members = members.joins("inner join metamap_node_participants p_mnp_3 on (p_mnp_3.participant_id=participants.id and p_mnp_3.metamap_id=3 and p_mnp_3.metamap_node_id=#{self.gender})")   
    end
    members
  end

  def is_member_of(p)
    # Figure out if somebody is a member of one of the member communities, and thus member of the conversation
    for com_tag in p.tag_list_downcase
      community = Community.find_by_tagname(com_tag)
      if community and community.networks and community.networks.include?(self)
        return true
      end
    end
    return false
  end

end
