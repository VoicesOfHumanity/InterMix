class CommunityParticipant < ApplicationRecord
    belongs_to :community
    belongs_to :participant
end
