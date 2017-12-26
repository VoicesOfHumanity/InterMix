class CommunityAdmin < ActiveRecord::Base
  belongs_to :community
  belongs_to :participant
end
