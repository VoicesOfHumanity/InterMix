class NetworkCommunity < ApplicationRecord
  belongs_to :network
  belongs_to :community
  belongs_to :participant, :foreign_key => :created_by
end
