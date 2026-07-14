class CommunityAdmin < ActiveRecord::Base
  belongs_to :community, optional: true
  belongs_to :participant, optional: true
end
