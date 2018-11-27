class ConversationCommunity < ApplicationRecord
  belongs_to :conversation
  belongs_to :community
end
