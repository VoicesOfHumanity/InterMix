class NetworkCommunity < ApplicationRecord
  belongs_to :network, optional: true
  belongs_to :community, optional: true
  belongs_to :participant, optional: true, :foreign_key => :created_by
end
