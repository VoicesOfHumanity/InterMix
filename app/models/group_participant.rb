class GroupParticipant < ActiveRecord::Base
  belongs_to :group, :counter_cache => true
  belongs_to :participant  
  
  def subtags
    # Return a list of subtags (sub-groups) for this member in this group
    subtag_string = ''
    group_subtag_participants = GroupSubtagParticipant.where(:group_id=>self.group_id,:participant_id=>self.participant_id).includes(:group_subtag)
    for gsp in group_subtag_participants
      subtag_string += gsp.group_subtag.tag
    end
    return subtag_string
  end
end
