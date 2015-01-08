class GroupParticipantsController < ApplicationController

  before_filter :authenticate_user_from_token!
  before_filter :authenticate_participant!

  def remove
    #-- Remove a person from the group

    active = params[:active].to_i
    
    group_participant_id = params[:id]
    group_participant = GroupParticipant.find_by_id(group_participant_id)
    
    group_id = group_participant.group_id
    participant_id = group_participant.participant_id
    
    participant = Participant.find_by_id(participant_id)

    group_subtag_participants = GroupSubtagParticipant.where(:group_id=>group_id,:participant_id=>participant_id)
    for gsp in group_subtag_participants
      gsp.destroy
    end  

    group_participant.destroy

    flash[:notice] = "Group member #{participant ? participant.name : participant_id} removed"
    
    url = "/groups/#{group_id}/members"
    if active >= 0
      url += "?active=#{active}"
    end
    redirect_to url
    
  end  


end
