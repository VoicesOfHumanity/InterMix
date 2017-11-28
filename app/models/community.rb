class Community < ActiveRecord::Base
  
  attr_accessor :members
  attr_accessor :activity
  
  def member_count
    Participant.tagged_with(self.tagname).count
  end
  
  def activity_count
    #-- Count the number of messages in the past month    
    Item.where("intra_com='@#{self.tagname}'").where('created_at > ?', 31.days.ago).count
  end
  
end
