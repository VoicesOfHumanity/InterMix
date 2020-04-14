class Network < ApplicationRecord

  has_many :communities, :through => :conversation_communities
  belongs_to :participant, :foreign_key => :created_by

end
