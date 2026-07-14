class HubAdmin < ActiveRecord::Base
  belongs_to :hub, optional: true
  belongs_to :participant, optional: true
end
