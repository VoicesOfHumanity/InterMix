class Conversation < ApplicationRecord
  has_many :conversation_communities
  has_many :communities, :through => :conversation_communities
  
  attr_accessor :activity
  
  def activity_count
    #-- Count the number of messages in the conversation in the past month 
    #Item.where("intra_com='@#{self.tagname}'").where('created_at > ?', 31.days.ago).count    
    Item.where("conversation_id=#{self.id}").where('created_at > ?', 31.days.ago).count
  end
  
end
