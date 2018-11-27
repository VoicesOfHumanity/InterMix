class Conversation < ApplicationRecord
  has_many :conversation_communities
  has_many :communities, :through => :conversation_communities
end
