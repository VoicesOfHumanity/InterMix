class Network < ApplicationRecord

  has_many :network_communities
  has_many :communities, :through => :network_communities
  belongs_to :participant, :foreign_key => :created_by

end
