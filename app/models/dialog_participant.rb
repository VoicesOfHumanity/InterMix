class DialogParticipant < ActiveRecord::Base
  belongs_to :dialog
  belongs_to :participant
end
