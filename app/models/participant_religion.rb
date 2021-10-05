class ParticipantReligion < ApplicationRecord
  belongs_to :participant
  belongs_to :religion
end
