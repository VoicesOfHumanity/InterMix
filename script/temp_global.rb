# Join everybody into the Global Townhall Square, if they aren't already there

require File.dirname(__FILE__)+'/cron_helper'

group_id = GLOBAL_GROUP_ID

added = 0

participants = Participant.all
for participant in participants
  group_participant = GroupParticipant.where(group_id: group_id, participant_id: participant.id).first
  if not group_participant
    group_participant = GroupParticipant.create(group_id: group_id, participant_id: participant.id, active: true, status: 'active')
    added += 1
  end
end

puts "#{added} of #{participants.length} added"