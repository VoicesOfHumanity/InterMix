class Network < ApplicationRecord

  has_many :network_communities
  has_many :communities, :through => :network_communities
  belongs_to :participant, :foreign_key => :created_by

  attr_accessor :activity

  def community_tags
    self.communities.collect{|com| com.tagname}
  end

  def activity_count
    #-- Count the number of messages in the network in the past month 
    #-- To count as being posted in the network, a message must have hashtags for all of the network communities.

    # The tags are in item.tag_list, but not sure how to do a query based on and-and there

    q = Item.where('created_at > ?', 31.days.ago)
    for tag in self.community_tags
      q = q.where("html_content like '##{tag}'")
    end
    q.count    
  end
  
  def members
    members = []
    for comtag in self.community_tags
      com_members = Participant.tagged_with(comtag).where(status: 'active', no_email: false)
      members << com_members
    end
    members.uniq
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
