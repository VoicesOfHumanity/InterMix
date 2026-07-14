class HubAdmin < ActiveRecord::Base
  belongs_to :hubs, optional: true
  belongs_to :participant, optional: true
end
