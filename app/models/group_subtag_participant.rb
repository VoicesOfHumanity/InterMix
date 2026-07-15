class GroupSubtagParticipant < ActiveRecord::Base
  belongs_to :group_subtag, optional: true
  belongs_to :participant, optional: true
end
