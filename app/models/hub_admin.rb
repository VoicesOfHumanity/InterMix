class HubAdmin < ActiveRecord::Base
  belongs_to :hubs
  belongs_to :participant
end
