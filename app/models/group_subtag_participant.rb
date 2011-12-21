class GroupSubtagParticipant < ActiveRecord::Base
  belongs_to :group_subtag
  belongs_to :participant
end
