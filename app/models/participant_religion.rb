class ParticipantReligion < ApplicationRecord
  belongs_to :participant, optional: true
  belongs_to :religion, optional: true
end
