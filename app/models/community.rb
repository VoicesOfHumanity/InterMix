class Community < ActiveRecord::Base
  
  
  def member_count
    Participant.tagged_with(self.tagname).count
  end
  
end
