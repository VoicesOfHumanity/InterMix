class Community < ActiveRecord::Base
  
  attr_accessor :members
  
  def member_count
    Participant.tagged_with(self.tagname).count
  end
  
end
