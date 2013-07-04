class GroupParticipantStatus < ActiveRecord::Migration
  def change
    add_column :group_participants, :status, :string, :after => :active, :default => 'active'
    group_participants = GroupParticipant.includes(:participant).all
    for group_participant in group_participants
      if group_participant.active and group_participant.participant and group_participant.participant.status=='active'
        group_participant.status = 'active'
      else
        group_participant.status = 'pending'
      end    
      group_participant.save!
    end
    add_column :groups, :message_visibility, :string, :after => :openness, :default => 'public'     
  end
end
